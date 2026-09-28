@testset "Boundary degeneracy and search-cap reporting" begin
    t = collect(0.:4.); x = ones(5)
    p = profile(x, t, 0.)
    @test p.kappa == 0.
    @test p.degenerate
    @test p.sigma2 == 0.
    @test p.loglik == Inf
    @test_throws ArgumentError fit_profile(x, t)
    x, t = fixture_data(FIXTURES, "regular")
    f = fit_profile(x, t; cap=.01)
    @test f.hit_upper_cap
    @test f.status == "tail_or_cap_warning"
    @test f.cap == .01
    @test f.profile.kappa <= f.cap
    # A fitted search cap is an optimizer diagnostic; it is never stored as
    # a finite confidence endpoint or a certified global optimum.
    @test !hasproperty(f, :upper_endpoint)
    @test !hasproperty(f, :certified_global)
    @test profile(x, t, 0.).kappa == 0.
    @test isapprox(profile(x, t, 1e-12).loglik, profile(x, t, 0.).loglik; atol=1e-9)
    @test isapprox(profile(x, t, 1e5).loglik, iid_limit(x); atol=1e-9)
    @test iid_limit([-.4, .3, .3, .3]) == Inf
    @test_throws DomainError profile([0., 1e-200, -1e-200, 2e-200], [0., 1., 2., 3.], 0.)
    times = collect(range(0., 1.; length=9))
    observed = simulate(times, .1; innovations=[.2, -.8, .4, 1.1, -.3, .5, -.4, .2])
    limited = fit_profile(observed, times; max_iterations=1)
    @test limited.optimizer_failures > 0
    @test occursin("numerical", limited.status)
    @test limited.evaluations >= 65
end
