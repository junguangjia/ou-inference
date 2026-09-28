"""
    kl_continuous(c)

KL(P_OU || P_Brownian) for continuous observation, known a=0 and σ, fixed X₀=0,
and c=κT: `c/4 - (1-exp(-2c))/8`. The small-c series avoids cancellation.
This restricted-submodel calculation is not a general unknown-nuisance bound.
"""
function kl_continuous(c::Real)
    value = _finite(c, "c")
    value >= 0 || throw(ArgumentError("c must be nonnegative."))
    answer = if value < 1e-4
        value^2 * (1 / 4 - value / 6 + value^2 / 12 - value^3 / 30 + value^4 / 90)
    else
        value / 4 + expm1(-2value) / 8
    end
    answer > 0 || value == 0 || throw(DomainError(value, "Positive KL underflow."))
    return answer
end

"""
    kl_discrete(kappa, times)

Exact Gaussian-chain KL for the same known-a=0, known-σ, X₀=0 submodel as
`kl_continuous`, conditional on a deterministic/exogenous schedule. Time origin
is irrelevant. Discrete observations cannot exceed continuous-path information.
"""
function kl_discrete(kappa::Real, times::AbstractVector{<:Real})
    t, gaps = _times(times)
    phi, _, v = coefficients(kappa, gaps)
    k = Float64(kappa)
    k == 0 && return 0.0
    total = 0.0
    for i in eachindex(gaps)
        elapsed = t[i] - t[1]
        prior_v = elapsed == 0 ? 0.0 : last(coefficients(k, elapsed))
        z = k * gaps[i]
        ratio = v[i] / gaps[i]
        # For tiny ratio, log(v)-log(gap) stays meaningful even if ratio
        # underflows; log1p(ratio-1) would spuriously become -Inf.
        # Subtracting 1 from v/gap loses all or much of the O(z) term at
        # tiny z, even while the O(z²) KL is representable. Expand that
        # difference directly; this corrects a frozen Python edge case.
        u = z < 1e-4 ?
            z * evalpoly(z, (-1.0, 2 / 3, -1 / 3, 2 / 15, -2 / 45, 4 / 315)) :
            ratio - 1
        variance_term = if abs(u) < 1e-5
            u^2 / 2 - u^3 / 3 + u^4 / 4
        elseif ratio > 0.5
            u - log1p(u)
        else
            ratio - 1 - (log(v[i]) - log(gaps[i]))
        end
        mean_change = -expm1(-z)
        mean_term = (mean_change / sqrt(gaps[i]) * sqrt(prior_v))^2
        term = variance_term + mean_term
        isfinite(term) || throw(DomainError(i, "Discrete KL arithmetic overflow; rescale time."))
        total += term
    end
    isfinite(total) || throw(DomainError(total, "Discrete KL sum overflow."))
    answer = 0.5 * total
    answer > 0 || throw(DomainError(kappa, "Positive discrete KL underflow."))
    return answer
end

"""
    pinsker_power_bound(c, alpha=0.05)

Continuous-path upper bound `min(1, alpha + sqrt(KL/2))` on power of a level-α
test against the restricted OU alternative of `kl_continuous`. Also bounds any
sampled-path test in that submodel; it is generally loose, not an attained power.
"""
function pinsker_power_bound(c::Real, alpha::Real = 0.05)
    level = _finite(alpha, "alpha")
    0 <= level <= 1 || throw(ArgumentError("alpha must lie in [0,1]."))
    return min(1.0, level + sqrt(kl_continuous(c) / 2))
end
