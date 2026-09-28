function _check_split(n::Int, split::Integer)
    split >= 3 && n - split >= 3 ||
        throw(ArgumentError("At least three transitions in each part are required."))
    return Int(split)
end

"""
    split_numerator(x, times, split) -> (log_numerator, training_fit)

Fit the first `split` transitions, then freeze the OU parameters and evaluate
the suffix conditional on its observed boundary state. All fitting choices and
warnings are returned in `training_fit`. Future observations never enter fitting.
"""
function split_numerator(x::AbstractVector{<:Real}, times::AbstractVector{<:Real}, split::Integer)
    y, t, _ = _observations(x, times)
    m = _check_split(length(y) - 1, split)
    fit = fit_profile(y[1:(m + 1)], t[1:(m + 1)])
    p = fit.profile
    numerator = loglik(y[(m + 1):end], t[(m + 1):end], p.kappa, p.a, p.sigma2)
    return numerator, fit
end

"""
    split_log_e(x, times, kappa, split; numerator=nothing)

Chronological universal-inference specialization: log normalized training-only
conditional density minus the full analytic suffix nuisance profile. A supplied
`numerator` must be the log of that frozen conditional density; callers must
preserve training-only measurability. No variance floor is applied. An infinite
denominator supremum produces `-Inf`, corresponding to an e-value of zero.

This is fixed-horizon model-based inference, not an anytime or robustness claim.
Floating-point profiles have not been certified as conservative upper bounds.
"""
function split_log_e(x::AbstractVector{<:Real}, times::AbstractVector{<:Real},
                     kappa::Real, split::Integer; numerator::Union{Nothing,Real} = nothing)
    y, t, _ = _observations(x, times)
    m = _check_split(length(y) - 1, split)
    num = isnothing(numerator) ? first(split_numerator(y, t, m)) : Float64(numerator)
    (isfinite(num) || num == -Inf) || throw(ArgumentError("Numerator must be finite or -Inf."))
    denominator = profile(y[(m + 1):end], t[(m + 1):end], kappa).loglik
    return num - denominator
end
