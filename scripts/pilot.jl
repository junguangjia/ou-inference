using OUInference, Random, Statistics, TOML

"""Immutable DEVELOPMENT configuration; independent trajectory is the uncertainty unit."""
Base.@kwdef struct PilotConfig
    repetitions::Int = 2
    seed::Int = 2026092803
    alpha::Float64 = 0.05
    horizon::Float64 = 1.0
    a::Float64 = 0.0
    sigma::Float64 = 1.0
    x0::Float64 = 0.0
end

function wilson(successes, total)
    z = 1.959963984540054
    p = successes / total
    denominator = 1 + z^2 / total
    center = (p + z^2 / (2total)) / denominator
    half = z * sqrt(p * (1 - p) / total + z^2 / (4total^2)) / denominator
    return max(0.0, center - half), min(1.0, center + half)
end

function write_csv(path, rows)
    isempty(rows) && error("No rows to write")
    names = propertynames(first(rows))
    open(path, "w") do io
        println(io, join(string.(names), ','))
        for row in rows
            println(io, join((getproperty(row, name) for name in names), ','))
        end
    end
end

function pilot(out::AbstractString, config::PilotConfig = PilotConfig())
    config.repetitions >= 2 || throw(ArgumentError("At least two trajectories per cell"))
    config.alpha == 0.05 || throw(ArgumentError("This diagnostic uses the fixed chi-square(1) 0.95 quantile"))
    ispath(out) && error("Refusing to overwrite output directory")
    mkpath(out)
    started = time()
    rows = NamedTuple[]
    summaries = NamedTuple[]
    trajectory = 0
    cutoff = 3.841458820694124 # Diagnostic only: not calibrated at the boundary.
    for design in ("regular", "alternating"), kappa in (0.0, 0.1, 1.0, 4.0), n in (64, 256)
        gaps = design == "regular" ? ones(n) : repeat([0.25, 1.75], n ÷ 2)
        times = vcat(0.0, cumsum(config.horizon .* gaps ./ sum(gaps)))
        cell = NamedTuple[]
        for rep in 1:config.repetitions
            trajectory += 1
            seed = config.seed + trajectory
            row = try
                x = simulate(times, kappa; a=config.a, sigma=config.sigma, x0=config.x0, rng=Xoshiro(seed))
                fit = fit_profile(x, times)
                numerator, training = split_numerator(x, times, n ÷ 2)
                lr_truth = 2 * (fit.profile.loglik - profile(x, times, kappa).loglik)
                lr_zero = 2 * (fit.profile.loglik - profile(x, times, 0.0).loglik)
                e_truth = split_log_e(x, times, kappa, n ÷ 2; numerator=numerator)
                e_zero = split_log_e(x, times, 0.0, n ÷ 2; numerator=numerator)
                (; design, kappa, T=config.horizon, n, replicate=rep, seed,
                   a=config.a, sigma=config.sigma, x0=config.x0,
                   status="completed", failure="none", kappa_hat=fit.profile.kappa,
                   fit_status=fit.status, training_status=training.status,
                   fit_cap=fit.cap, training_cap=training.cap,
                   fit_optimizer_failures=fit.optimizer_failures, fit_numerical_failures=fit.numerical_failures,
                   training_optimizer_failures=training.optimizer_failures, training_numerical_failures=training.numerical_failures,
                   fit_warning=Int(fit.status != "bounded_search_completed"),
                   training_warning=Int(training.status != "bounded_search_completed"),
                   lr_contains_truth=Int(lr_truth <= cutoff), lr_excludes_zero=Int(lr_zero > cutoff),
                   split_contains_truth=Int(e_truth <= -log(config.alpha)),
                   split_excludes_zero=Int(e_zero > -log(config.alpha)), log_e_truth=e_truth, log_e_zero=e_zero)
            catch err
                err isa InterruptException && rethrow()
                (; design, kappa, T=config.horizon, n, replicate=rep, seed,
                   a=config.a, sigma=config.sigma, x0=config.x0,
                   status="failed", failure=string(nameof(typeof(err))), kappa_hat=NaN,
                   fit_status="failed", training_status="failed",
                   fit_cap=NaN, training_cap=NaN, fit_optimizer_failures=-1, fit_numerical_failures=-1,
                   training_optimizer_failures=-1, training_numerical_failures=-1,
                   fit_warning=1, training_warning=1,
                   lr_contains_truth=-1, lr_excludes_zero=-1, split_contains_truth=-1,
                   split_excludes_zero=-1, log_e_truth=NaN, log_e_zero=NaN)
            end
            push!(rows, row); push!(cell, row)
        end
        failures = count(r -> r.status == "failed", cell)
        for metric in (:lr_contains_truth, :lr_excludes_zero, :split_contains_truth, :split_excludes_zero)
            successes = count(r -> getproperty(r, metric) == 1, cell)
            total = length(cell)
            lower, _ = wilson(successes, total)
            _, upper = wilson(successes + failures, total)
            push!(summaries, (; design, kappa, T=config.horizon, n, metric=string(metric),
                attempted=total, completed=total-failures, failures, successes,
                rate_lower=successes/total, rate_upper=(successes+failures)/total,
                mcse=failures==0 ? sqrt((successes/total)*(1-successes/total)/total) : NaN,
                wilson_lower=lower, wilson_upper=upper,
                fit_warnings=sum(r.fit_warning for r in cell),
                training_warnings=sum(r.training_warning for r in cell)))
        end
    end
    write_csv(joinpath(out, "replicates.csv"), rows)
    write_csv(joinpath(out, "summary.csv"), summaries)
    info = [(; c, n, discrete_KL=kl_discrete(c, collect(range(0, 1; length=n+1))),
              continuous_KL=kl_continuous(c), level_05_power_bound=min(1.0, 0.05+sqrt(kl_continuous(c)/2)))
            for c in (0.1, 1.0, 4.0) for n in (8, 32, 128, 2048)]
    write_csv(joinpath(out, "information.csv"), info)
    metadata = Dict("status"=>"DEVELOPMENT", "julia_version"=>string(VERSION),
        "seed"=>config.seed, "rng"=>"Xoshiro; fresh RNG with recorded seed for each trajectory",
        "replications_per_cell"=>config.repetitions, "trajectories"=>trajectory,
        "failures"=>count(r->r.status=="failed", rows), "runtime_seconds"=>time()-started,
        "T"=>config.horizon, "n"=>[64,256], "a"=>config.a, "sigma"=>config.sigma, "x0"=>config.x0,
        "kappa"=>[0.0,0.1,1.0,4.0], "alpha"=>config.alpha,
        "schedules"=>["regular", "alternating normalized gaps 0.25 and 1.75"],
        "methods"=>["uncalibrated chi-square LR diagnostic", "chronological split profile e-value"],
        "warnings"=>["No continuum endpoints or set widths", "Bounded fit is not a certified global MLE",
            "Different n and schedules are not nested paths", "RNG streams differ from Python",
            "Failed trajectories remain in denominators through lower/upper rate bounds",
            "Wilson envelopes describe Monte Carlo uncertainty, not method validity",
            "Zero or perfect observed rates do not establish zero risk or exact coverage"])
    open(joinpath(out, "metadata.toml"), "w") do io; TOML.print(io, metadata; sorted=true); end
    println("DEVELOPMENT trajectories: ", trajectory, "; failures: ", metadata["failures"])
    println("Restricted c=0.1 path KL: ", kl_continuous(0.1), "; level-0.05 power bound: ", info[1].level_05_power_bound)
    return metadata
end
