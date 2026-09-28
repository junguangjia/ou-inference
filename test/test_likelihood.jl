@testset "Conditional Gaussian likelihood" begin
    x, t = example(); n = length(x) - 1
    phi, b, v = coefficients(.7, diff(t))
    residual = x[2:end] .- phi .* x[1:end-1] .- .3 .* b
    expected = sum(-log(2pi) / 2 .- log.(.36 .* v) ./ 2 .- residual.^2 ./ (2 .* .36 .* v))
    @test isapprox(loglik(x, t, .7, .3, .36), expected; atol=1e-10, rtol=1e-12)
    @test loglik(x, t, .7, .3, .36) ≈
          loglik(x[1:61], t[1:61], .7, .3, .36) + loglik(x[61:end], t[61:end], .7, .3, .36)
    @test loglik(x, 365 .* t, .7 / 365, .3 / 365, .36 / 365) ≈ expected
    for scale in (-3., 7.)
        offset = -5.
        @test loglik(scale .* x .+ offset, t, .7, scale * .3 + .7 * offset, scale^2 * .36) ≈
              expected - n * log(abs(scale))
    end
    @test_throws ArgumentError profile([1., 2., 3., 4.], [0., 1., 1., 3.], 1.)
    @test_throws ArgumentError profile([1., 2., 3.], [0., 1., 2.], 1.)
    @test_throws ArgumentError loglik(x, t, .7, .3, 0.)
    @test_throws ArgumentError loglik(x, t, .7, NaN, 1.)
end

@testset "Restricted information calculation" begin
    @test kl_continuous(0.) == 0.
    @test isapprox(kl_continuous(1e-7) / 1e-14, .25; rtol=1e-6)
    @test pinsker_power_bound(0.) == .05
    @test pinsker_power_bound(100.) == 1.
    # The frozen Python ratio v/gap-1 loses precision here. The independent
    # small-k Gaussian KL expansion fixes the target before testing Julia.
    for k in (1e-16, 1e-18), n in (1, 4, 64)
        value = kl_discrete(k, collect(range(0., 1.; length=n+1)))
        @test isapprox(value, k^2 / 4; atol=0., rtol=1e-14)
        @test value <= kl_continuous(k) * (1 + 1e-14)
    end
    # Absolute fixture tolerances intentionally do not certify relative accuracy
    # for vanishing KL. A separate 256-bit formula checks that difficult regime.
    for k in (1e-18, 1e-16, 1e-10, 1e-5, .1, 1., 7.)
        for t in (collect(range(0., 1.; length=21)), [0., .01, .2, .55, 1.])
            reference = setprecision(BigFloat, 256) do
                kb = BigFloat(k); tb = BigFloat.(t); total = BigFloat(0)
                for i in 1:length(tb)-1
                    gap = tb[i+1] - tb[i]
                    v = -expm1(-2 * kb * gap) / (2 * kb)
                    previous_v = -expm1(-2 * kb * (tb[i] - tb[1])) / (2 * kb)
                    u = v / gap - 1
                    total += (u - log1p(u) + expm1(-kb * gap)^2 * previous_v / gap) / 2
                end
                Float64(total)
            end
            @test isapprox(kl_discrete(k, t), reference; atol=0., rtol=1e-12)
        end
    end
    for k in (.1, 1., 4.)
        values = [kl_discrete(k, collect(range(0., 1.; length=n+1))) for n in (8, 32, 128, 2048)]
        @test all(>(0.), diff(values))
        @test values[end] <= kl_continuous(k) + 1e-10
        @test abs(values[end] - kl_continuous(k)) < .003
        t = [0., .01, .2, .8, 1.]
        @test kl_discrete(k, t) ≈ kl_discrete(k / 365, 365 .* t)
        @test kl_discrete(k, t .+ 10.) ≈ kl_discrete(k, t)
    end
end
