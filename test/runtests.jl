using Test
using Random
using Statistics
using SHA
using OUInference

const FIXTURES = joinpath(@__DIR__, "fixtures", "v1")
include("cross_language_helpers.jl")

function example()
    t = collect(range(0., 12.; length=121))
    x = simulate(t, .7; a=.3, sigma=.6, x0=-.2, rng=Xoshiro(412))
    x, t
end

@testset "OUInference" begin
    include("test_transition.jl")
    include("test_likelihood.jl")
    include("test_profile.jl")
    include("test_boundary.jl")
    include("test_cross_language.jl")
end
