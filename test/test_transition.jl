@testset "Exact transition and boundary continuity" begin
    gaps = [.01, .2, 2.]
    phi, b, v = coefficients(0., gaps)
    @test phi == ones(3)
    @test b == gaps
    @test v == gaps
    phi, b, v = coefficients(1e-12, gaps)
    @test isapprox(b, gaps; rtol=3e-12, atol=0.)
    @test isapprox(v, gaps; rtol=3e-12, atol=0.)
    @test isapprox(phi, ones(3); rtol=3e-12, atol=0.)
    for k in (0., 1e-10, .7, 20.)
        ph, b, v = coefficients(k, [.2, .4, .6])
        @test ph[3] ≈ ph[2] * ph[1]
        @test b[3] ≈ ph[2] * b[1] + b[2]
        @test v[3] ≈ ph[2]^2 * v[1] + v[2]
        @test all(>(0.), v)
        regular = coefficients(k, fill(.125, 8))
        generic = coefficients(k, diff(collect(0.:.125:1.)))
        @test regular == generic
    end
    for (k, d) in ((-1., [1.]), (NaN, [1.]), (1., [0.]), (1., [-1.]), (1., [NaN]))
        @test_throws ArgumentError coefficients(k, d)
    end
    phi, b, v = coefficients(nextfloat(0.), [1.])
    @test phi == [1.]
    @test b == [1.]
    @test v == [1.]
    phi, b, v = coefficients(floatmax(Float64), [1.])
    @test phi == [0.]
    @test all(>(0.), b)
    @test all(>(0.), v)
end

@testset "Exact simulation and explicit RNG" begin
    t = [0., .1, .4, 1.]; z = [.2, -1., 2.]
    x = simulate(t, 0.; a=.8, sigma=1.2, x0=-2., innovations=z)
    expected = vcat(-2., -2. .+ cumsum(.8 .* diff(t) .+ 1.2 .* sqrt.(diff(t)) .* z))
    @test x ≈ expected
    @test simulate(t, .4; rng=Xoshiro(17)) == simulate(t, .4; rng=Xoshiro(17))
    @test_throws ArgumentError simulate(t, .4)
    @test_throws ArgumentError simulate(t, .4; innovations=[1.])
    @test_throws ArgumentError simulate(t, .4; sigma=0., innovations=z)
    @test_throws ArgumentError simulate(t, .4; rng=Xoshiro(17), innovations=z)
    Random.seed!(73); expected_global = rand(8)
    Random.seed!(73); simulate(t, .4; rng=Xoshiro(9))
    @test rand(8) == expected_global
    for design in ("regular", "irregular")
        rows = filter(r -> r["design"] == design, fixture_rows(joinpath(FIXTURES, "observations.csv")))
        x, t = fixture_data(FIXTURES, design)
        z = [fixture_number(r, "innovation") for r in rows[2:end]]
        @test isapprox(simulate(t, .2; a=.3, sigma=.7, x0=-.4, innovations=z), x;
                       atol=1e-12, rtol=1e-12)
    end
end

@testset "Exact simulation endpoint moments" begin
    # Six standard errors fixed in advance for six independent design cells.
    # The sampling unit is one independently simulated trajectory, not one time.
    N = 12_000; a = .3; sigma = .7; x0 = -.4
    for (design_id, t) in enumerate(([0., .25, .5, .75, 1.], [0., .01, .2, .55, 1.]))
        for (k_id, k) in enumerate((0., 1e-8, .7))
            rng = Xoshiro(2026092803 + 10 * design_id + k_id)
            endpoints = [simulate(t, k; a, sigma, x0, rng)[end] for _ in 1:N]
            phi, b, v = coefficients(k, [1.])
            m = phi[1] * x0 + a * b[1]; s2 = sigma^2 * v[1]
            @test abs(mean(endpoints) - m) <= 6 * sqrt(s2 / N)
            @test abs(var(endpoints) - s2) <= 6 * s2 * sqrt(2 / (N - 1))
        end
    end
end
