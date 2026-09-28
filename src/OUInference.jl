"""
Exact scalar Ornstein–Uhlenbeck inference, conditional on a fixed observed X₀.

The model is dX = (a - κX)dt + σdW, with a ∈ ℝ, κ ≥ 0, and σ > 0.
Observation times must be fixed or exogenous. This module implements an existing
Gaussian likelihood and a universal-inference specialization, not a new method.
"""
module OUInference

using Random: AbstractRNG, randn

export Profile, Fit, coefficients, simulate, loglik, profile, iid_limit,
       fit_profile, split_numerator, split_log_e, kl_continuous, kl_discrete,
       pinsker_power_bound

const LOG2PI = log(2π)

include("transition.jl")
include("simulation.jl")
include("likelihood.jl")
include("profile.jl")
include("inference.jl")
include("information.jl")

end
