"""
    loglik(x, times, kappa, a, sigma2)

Exact Gaussian conditional log likelihood given the observed first state.
`sigma2` is the diffusion variance, not the transition variance. There is no
stationary initial density and no regression degrees-of-freedom correction.
"""
function loglik(x::AbstractVector{<:Real}, times::AbstractVector{<:Real},
                kappa::Real, a::Real, sigma2::Real)
    y, _, gaps = _observations(x, times)
    aa, s2 = _finite(a, "a"), _finite(sigma2, "sigma2")
    s2 > 0 || throw(ArgumentError("sigma2 must be positive."))
    phi, b, v = coefficients(kappa, gaps)
    total = 0.0
    for i in eachindex(gaps)
        residual = y[i + 1] - phi[i] * y[i] - aa * b[i]
        standardized = (residual / sqrt(v[i])) / sqrt(s2)
        term = LOG2PI + log(s2) + log(v[i]) + standardized^2
        isfinite(term) || throw(DomainError(i, "Log-likelihood arithmetic overflow; rescale state/time."))
        total += term
    end
    isfinite(total) || throw(DomainError(total, "Log-likelihood sum overflow."))
    return -0.5 * total
end
