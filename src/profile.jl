"Analytic fixed-κ nuisance profile; `degenerate` means an infinite supremum at RSS=0."
struct Profile
    kappa::Float64
    a::Float64
    sigma2::Float64
    loglik::Float64
    degenerate::Bool
end

"Bounded numerical fit, with explicit cap/tail and failed-evaluation diagnostics."
struct Fit
    profile::Profile
    cap::Float64
    hit_upper_cap::Bool
    iid_limit_loglik::Float64
    tail_better::Bool
    status::String
    optimizer_failures::Int
    numerical_failures::Int
    evaluations::Int
end

"""
    profile(x, times, kappa) -> Profile

Analytic supremum over unrestricted `a` and `sigma2 > 0`. With
`rᵢ=xᵢ-phiᵢ*xᵢ₋₁`, weighted least squares gives
`ahat=sum(bᵢ*rᵢ/vᵢ)/sum(bᵢ²/vᵢ)`, and `sigma2hat=RSS/n`.

No variance floor is permitted: exact zero RSS gives log likelihood `Inf`.
Floating-point evaluation is not a certified upper bound on the exact supremum.
Nonzero residuals whose variance underflows raise an explicit numerical error.
"""
function profile(x::AbstractVector{<:Real}, times::AbstractVector{<:Real}, kappa::Real)
    y, _, gaps = _observations(x, times)
    phi, b, v = coefficients(kappa, gaps)
    n = length(gaps)
    r = Vector{Float64}(undef, n)
    w = similar(r)
    z = similar(r)
    for i in eachindex(gaps)
        r[i] = y[i + 1] - phi[i] * y[i]
        w[i] = b[i] / sqrt(v[i])
        z[i] = r[i] / sqrt(v[i])
    end
    (all(isfinite, r) && all(isfinite, w) && all(isfinite, z)) ||
        throw(DomainError(kappa, "Weighted profile arithmetic overflow; rescale state/time."))
    # Scaling the sole design column leaves weighted least squares unchanged.
    wscale = maximum(w)
    wscale > 0 || throw(DomainError(kappa, "Profile design column underflow."))
    numerator, denominator = 0.0, 0.0
    for i in eachindex(w)
        u = w[i] / wscale
        numerator += u * z[i]
        denominator += u^2
    end
    ahat = (numerator / denominator) / wscale
    isfinite(ahat) || throw(DomainError(kappa, "Profile drift is not representable."))
    rss, nonzero_residual = 0.0, false
    for i in eachindex(r)
        residual = r[i] - ahat * b[i]
        nonzero_residual |= residual != 0
        rss += (residual / sqrt(v[i]))^2
    end
    if rss == 0 && !nonzero_residual
        return Profile(Float64(kappa), ahat, 0.0, Inf, true)
    end
    sigma2 = rss / n
    (isfinite(sigma2) && sigma2 > 0) ||
        throw(DomainError(kappa, "Nonzero profile variance overflow/underflow; rescale state/time."))
    ll = -0.5 * (n * (LOG2PI + log(sigma2) + 1) + sum(log, v))
    isfinite(ll) || throw(DomainError(kappa, "Profile log likelihood is not representable."))
    return Profile(Float64(kappa), ahat, sigma2, ll, false)
end

"""
    iid_limit(x)

Limit of the profiled log likelihood as κ→∞: the free-mean/free-variance iid
Gaussian likelihood of `x[2:end]`. Infinity is a limit, not an OU parameter point.
"""
function iid_limit(x::AbstractVector{<:Real})
    length(x) >= 2 || throw(ArgumentError("Need at least one transition."))
    y = Float64.(x[2:end])
    all(isfinite, y) || throw(ArgumentError("Observations must be finite."))
    n = length(y)
    all(==(first(y)), y) && return Inf
    center = sum(v -> v / n, y)
    isfinite(center) || throw(DomainError(center, "IID mean overflow."))
    residuals = y .- center
    variance = sum(abs2, residuals) / n
    if variance == 0 && all(iszero, residuals)
        return Inf
    end
    isfinite(variance) && variance > 0 ||
        throw(DomainError(variance, "Nonzero IID variance overflow/underflow; rescale state."))
    return -n / 2 * (LOG2PI + log(variance) + 1)
end

# A small bounded scalar search avoids a dependency for this one-dimensional
# problem. It is not a global optimizer; every result retains the coarse grid,
# κ=0, the finite cap, and the separately calculated κ→∞ limit.
function _golden_maximize(f, left, right, xatol, max_iterations)
    ratio = (sqrt(5.0) - 1) / 2
    c, d = right - ratio * (right - left), left + ratio * (right - left)
    fc, fd = f(c), f(d)
    for _ in 1:max_iterations
        tol = xatol + 4eps(Float64) * max(abs(left), abs(right))
        if right - left <= tol
            return fc >= fd ? (c, fc, true) : (d, fd, true)
        end
        if fc >= fd
            right, d, fd = d, c, fc
            c = right - ratio * (right - left)
            fc = f(c)
        else
            left, c, fc = c, d, fd
            d = left + ratio * (right - left)
            fd = f(d)
        end
    end
    return fc >= fd ? (c, fc, false) : (d, fd, false)
end

"""
    fit_profile(x, times; cap=nothing, grid_size=65, max_iterations=128) -> Fit

A bounded log-spaced grid plus local golden-section refinements. Default cap is
`200 / horizon`. This is sufficient to fit a normalized training-only numerator,
but is NOT a certified global MLE, confidence endpoint, or continuum inversion.
Numerical failures remain counted even if another candidate succeeds. A
zero-RSS profile cannot define a positive-variance fitted density and is rejected.
"""
function fit_profile(x::AbstractVector{<:Real}, times::AbstractVector{<:Real};
                     cap::Union{Nothing,Real} = nothing, grid_size::Integer = 65,
                     max_iterations::Integer = 128)
    y, t, _ = _observations(x, times)
    horizon = t[end] - t[1]
    upper = isnothing(cap) ? 200 / horizon : _finite(cap, "cap")
    (isfinite(upper) && upper > 0 && grid_size >= 5 && max_iterations >= 1) ||
        throw(ArgumentError("Finite positive cap, grid_size>=5, and max_iterations>=1 required."))
    lower = upper * 1e-9
    lower > 0 || throw(DomainError(upper, "Search grid underflow; rescale time."))
    grid = [0.0; exp.(range(log(lower), log(upper); length = grid_size - 1))]
    grid[end] = upper
    candidates = Profile[]
    evaluations, numerical_failures = 0, 0
    function evaluate(k)
        evaluations += 1
        p = try
            profile(y, t, k)
        catch err
            err isa DomainError || rethrow()
            numerical_failures += 1
            return -Inf
        end
        p.degenerate && throw(ArgumentError("Degenerate profile cannot define a positive-variance fitted density."))
        push!(candidates, p)
        return p.loglik
    end
    values = evaluate.(grid)
    xatol = 1e-10 / max(horizon, 1e-10)
    xatol > 0 || throw(DomainError(horizon, "Optimizer tolerance underflow; rescale time."))
    optimizer_failures = 0
    for j in 2:(length(grid) - 1)
        if isfinite(values[j]) && values[j] >= values[j - 1] && values[j] >= values[j + 1]
            _, value, converged = _golden_maximize(evaluate, grid[j - 1], grid[j + 1], xatol, max_iterations)
            optimizer_failures += !(converged && isfinite(value))
        end
    end
    isempty(candidates) && throw(ArgumentError("Every profile evaluation failed numerically."))
    best = candidates[argmax(p.loglik for p in candidates)]
    limit = iid_limit(y)
    hit = best.kappa >= upper * (1 - 1e-7)
    tail_better = limit > best.loglik + 1e-8
    status = if numerical_failures > 0 || optimizer_failures > 0
        hit || tail_better ? "numerical_and_tail_or_cap_warning" : "numerical_warning"
    else
        hit || tail_better ? "tail_or_cap_warning" : "bounded_search_completed"
    end
    return Fit(best, upper, hit, limit, tail_better, status,
               optimizer_failures, numerical_failures, evaluations)
end
