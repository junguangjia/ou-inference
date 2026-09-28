@testset "Analytic unrestricted nuisance profile" begin
    x, t = example(); n = length(x) - 1
    for k in (0., 1e-9, .7, 10.)
        p = profile(x, t, k)
        @test isapprox(p.loglik, loglik(x, t, k, p.a, p.sigma2); atol=1e-9)
        for a in (-1., 0., 1.), sigma2 in (.01, .36, 4.)
            @test p.loglik + 1e-9 >= loglik(x, t, k, a, sigma2)
        end
        for scale in (-3., 7.)
            offset = -5.; transformed = profile(scale .* x .+ offset, t, k)
            @test transformed.a ≈ scale * p.a + k * offset
            @test transformed.sigma2 ≈ scale^2 * p.sigma2
            @test transformed.loglik ≈ p.loglik - n * log(abs(scale))
        end
        transformed = profile(x, 365 .* t, k / 365)
        @test transformed.a ≈ p.a / 365
        @test transformed.sigma2 ≈ p.sigma2 / 365
        @test transformed.loglik ≈ p.loglik
    end
    p = profile(x, t, 0.)
    @test p.a ≈ (x[end] - x[1]) / (t[end] - t[1])
    # For equal gaps and an interior AR coefficient, conditional Gaussian OLS
    # and continuous-time profiling agree, using the MLE divisor n.
    x, t = fixture_data(FIXTURES, "regular")
    previous = x[1:end-1]; following = x[2:end]
    phi = sum((previous .- mean(previous)) .* (following .- mean(following))) /
          sum(abs2, previous .- mean(previous))
    intercept = mean(following) - phi * mean(previous)
    @test 0. < phi < 1.
    k = -log(phi) / (t[2] - t[1]); p = profile(x, t, k)
    _, b, v = coefficients(k, [t[2] - t[1]])
    @test p.a * b[1] ≈ intercept
    @test p.sigma2 * v[1] ≈ mean(abs2, following .- intercept .- phi .* previous)
end

@testset "Chronological split uses only its training prefix" begin
    x, t = example(); split = 60
    numerator, f = split_numerator(x, t, split)
    y = copy(x); y[split+2:end] .+= 1000.
    changed_numerator, g = split_numerator(y, t, split)
    @test f.profile == g.profile
    @test f.cap == g.cap
    @test numerator != changed_numerator
    @test numerator ≈ loglik(x[split+1:end], t[split+1:end],
                            f.profile.kappa, f.profile.a, f.profile.sigma2)
    e = split_log_e(x, t, .7, split; numerator)
    simple = numerator - loglik(x[split+1:end], t[split+1:end], .7, .3, .36)
    @test e <= simple + 1e-9
    @test e ≈ numerator - profile(x[split+1:end], t[split+1:end], .7).loglik
    scale = 3.; offset = 2.
    @test isapprox(e, split_log_e(scale .* x .+ offset, t, .7, split;
        numerator=numerator - (length(x)-1-split) * log(scale)); atol=1e-8)
    @test_throws ArgumentError split_numerator(x, t, 2)
end
