# Float64 is an explicit numerical implementation choice, not a model restriction.
function _finite(value::Real, name::AbstractString)
    x = Float64(value)
    isfinite(x) || throw(ArgumentError("$name must be finite and representable as Float64."))
    return x
end

function _times(times::AbstractVector{<:Real}; min_transitions::Int = 1)
    length(times) >= min_transitions + 1 ||
        throw(ArgumentError("Need at least $min_transitions transitions."))
    t = Float64.(times)
    all(isfinite, t) || throw(ArgumentError("Observation times must be finite."))
    d = diff(t)
    all(v -> isfinite(v) && v > 0, d) ||
        throw(ArgumentError("Times must be strictly increasing with finite positive gaps."))
    isfinite(t[end] - t[1]) ||
        throw(ArgumentError("Observation horizon overflow; rescale the time unit."))
    return t, d
end

function _observations(x::AbstractVector{<:Real}, times::AbstractVector{<:Real})
    length(x) == length(times) || throw(ArgumentError("Observation and time lengths must match."))
    t, d = _times(times; min_transitions = 3)
    y = Float64.(x)
    all(isfinite, y) || throw(ArgumentError("Observations must be finite."))
    return y, t, d
end

function _coefficient(kappa::Float64, gap::Float64)
    if kappa == 0
        return 1.0, gap, gap
    end
    z = kappa * gap
    isfinite(z) || throw(DomainError(kappa, "kappa*gap overflow; rescale time."))
    phi = exp(-z)
    # Ratio form preserves tiny κ, including products rounded to zero. For large
    # z use division by κ; forming 2κ can overflow although v is representable.
    if z == 0
        b, v = gap, gap
    elseif z <= 1
        b = gap * (-expm1(-z) / z)
        v = gap * (-expm1(-2z) / (2z))
    else
        b = -expm1(-z) / kappa
        v = (-0.5 * expm1(-2z)) / kappa
    end
    (isfinite(b) && b > 0 && isfinite(v) && v > 0) ||
        throw(DomainError(kappa, "Transition coefficients are not representable; rescale time."))
    return phi, b, v
end

"""
    coefficients(kappa, gaps) -> (phi, b, v)

Exact transition mean is `phi[i]*x + a*b[i]` and variance is `sigma^2*v[i]`.
At κ=0, `phi=1` and `b=v=gaps`: Brownian motion with unrestricted drift.
The scalar-gap overload returns scalar quantities. No positive κ floor is used.
"""
function coefficients(kappa::Real, gaps::AbstractVector{<:Real})
    k = _finite(kappa, "kappa")
    k >= 0 || throw(ArgumentError("kappa must be nonnegative."))
    d = Float64.(gaps)
    all(v -> isfinite(v) && v > 0, d) ||
        throw(ArgumentError("Gaps must be finite and positive."))
    phi, b, v = similar(d), similar(d), similar(d)
    for i in eachindex(d)
        phi[i], b[i], v[i] = _coefficient(k, d[i])
    end
    return phi, b, v
end

function coefficients(kappa::Real, gap::Real)
    k = _finite(kappa, "kappa")
    d = _finite(gap, "gap")
    k >= 0 || throw(ArgumentError("kappa must be nonnegative."))
    d > 0 || throw(ArgumentError("Gap must be positive."))
    return _coefficient(k, d)
end
