"""
    simulate(times, kappa; a=0, sigma=1, x0=0, rng=nothing, innovations=nothing)

Simulate exact Gaussian OU transitions. Supply exactly one explicit RNG or a
vector of standard-normal innovations. Common innovations at different meshes
are not nested continuous paths; subsample a single fine path for infill work.
"""
function simulate(times::AbstractVector{<:Real}, kappa::Real;
                  a::Real = 0, sigma::Real = 1, x0::Real = 0,
                  rng::Union{Nothing,AbstractRNG} = nothing,
                  innovations::Union{Nothing,AbstractVector{<:Real}} = nothing)
    t, gaps = _times(times)
    aa, ss, initial = _finite(a, "a"), _finite(sigma, "sigma"), _finite(x0, "x0")
    ss > 0 || throw(ArgumentError("sigma must be positive."))
    (isnothing(rng) != isnothing(innovations)) ||
        throw(ArgumentError("Supply exactly one explicit rng or innovations."))
    phi, b, v = coefficients(kappa, gaps)
    z = isnothing(innovations) ? randn(rng, length(gaps)) : Float64.(innovations)
    (length(z) == length(gaps) && all(isfinite, z)) ||
        throw(ArgumentError("Innovations must be finite with one per transition."))
    x = Vector{Float64}(undef, length(t))
    x[1] = initial
    for i in eachindex(gaps)
        scale = ss * sqrt(v[i])
        isfinite(scale) && scale > 0 ||
            throw(DomainError(i, "Transition standard deviation is not representable."))
        x[i + 1] = phi[i] * x[i] + aa * b[i] + scale * z[i]
        isfinite(x[i + 1]) || throw(DomainError(i, "Simulated state overflow; rescale state."))
    end
    return x
end

# Retain the reference's positional parameter order for deterministic audits.
simulate(times::AbstractVector{<:Real}, kappa::Real, a::Real,
         sigma::Real = 1, x0::Real = 0; kwargs...) =
    simulate(times, kappa; a, sigma, x0, kwargs...)
