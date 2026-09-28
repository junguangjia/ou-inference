# The fixture format deliberately contains no embedded commas or quoted escapes.
function fixture_rows(path)
    lines = readlines(path)
    cells(line) = [strip(field, ['"']) for field in split(strip(line), ',')]
    header = cells(first(lines))
    [Dict(zip(header, cells(line))) for line in lines[2:end] if !isempty(strip(line))]
end

fixture_number(row, key) = parse(Float64, row[key])

function fixture_data(directory, design)
    rows = filter(r -> r["design"] == design, fixture_rows(joinpath(directory, "observations.csv")))
    ([fixture_number(r, "x") for r in rows], [fixture_number(r, "t") for r in rows])
end

"""Compare two numerical routes using tolerances fixed before execution."""
function cross_language_comparisons(directory)
    comparisons = NamedTuple[]
    function add(source, category, actual, expected; atol=1e-10, rtol=1e-10)
        push!(comparisons, (; source, category, actual=Float64(actual),
                            expected=Float64(expected), atol, rtol))
    end
    for source in ("python", "r")
        base = source == "python" ? directory : joinpath(directory, "r")
        for row in fixture_rows(joinpath(base, source * "_transition.csv"))
            x, t = fixture_data(directory, row["design"])
            i = parse(Int, row["index"]); k = fixture_number(row, "kappa")
            phi, b, v = coefficients(k, diff(t))
            for (key, value) in (("phi", phi[i]), ("b", b[i]), ("v", v[i]),
                                  ("mean", phi[i] * x[i] + .3 * b[i]),
                                  ("variance", .49 * v[i]))
                add(source, key, value, fixture_number(row, key))
            end
        end
        for row in fixture_rows(joinpath(base, source * "_profile.csv"))
            x, t = fixture_data(directory, row["design"])
            k = fixture_number(row, "kappa"); p = profile(x, t, k)
            for key in ("a", "sigma2", "loglik")
                add(source, "profile_" * key, getproperty(p, Symbol(key)), fixture_number(row, key))
            end
            add(source, "given_loglik", loglik(x, t, k, .3, .49), fixture_number(row, "given_loglik"))
            fitted = fit_profile(x, t)
            add(source, "likelihood_ratio", 2 * (fitted.profile.loglik - p.loglik),
                fixture_number(row, "lr"); atol=1e-8, rtol=1e-8)
            if source == "python"
                add(source, "split_log_e", split_log_e(x, t, k, 10), fixture_number(row, "log_e");
                    atol=2e-5, rtol=2e-5)
            end
        end
        for row in fixture_rows(joinpath(base, source * "_information.csv"))
            _, t = fixture_data(directory, row["design"])
            k = fixture_number(row, "kappa"); c = k * (t[end] - t[1])
            add(source, "continuous_KL", kl_continuous(c), fixture_number(row, "continuous"))
            add(source, "discrete_KL", kl_discrete(k, t), fixture_number(row, "discrete"))
            add(source, "power_bound", pinsker_power_bound(c), fixture_number(row, "power"))
        end
    end
    for row in fixture_rows(joinpath(directory, "python_fit.csv"))
        x, t = fixture_data(directory, row["design"])
        f = fit_profile(x, t); numerator, train = split_numerator(x, t, 10)
        for (prefix, p) in (("", f.profile), ("training_", train.profile))
            for key in ("kappa", "a", "sigma2", "loglik")
                tol = key == "loglik" ? 1e-8 : 2e-5
                add("python", prefix * "fit_" * key, getproperty(p, Symbol(key)),
                    fixture_number(row, prefix * key); atol=tol, rtol=tol)
            end
        end
        add("python", "predictive_numerator", numerator, fixture_number(row, "numerator");
            atol=2e-5, rtol=2e-5)
        for key in ("cap", "hit_upper_cap", "tail_better", "iid_limit_loglik")
            add("python", key, getproperty(f, Symbol(key)), fixture_number(row, key))
        end
    end
    for row in fixture_rows(joinpath(directory, "r", "r_direct_nuisance.csv"))
        x, t = fixture_data(directory, row["design"])
        p = profile(x, t, fixture_number(row, "kappa"))
        for key in ("a", "sigma2", "loglik")
            tol = key == "loglik" ? 1e-9 : 5e-6
            add("r", "direct_nuisance_" * key, getproperty(p, Symbol(key)),
                fixture_number(row, key); atol=tol, rtol=tol)
        end
        add("r", "direct_nuisance_convergence", fixture_number(row, "convergence"), 0.)
    end
    comparisons
end

function comparison_passes(c)
    isfinite(c.actual) && isfinite(c.expected) &&
        abs(c.actual - c.expected) <= c.atol + c.rtol * abs(c.expected)
end

function comparison_summary(comparisons)
    keys = sort(unique((c.source, c.category) for c in comparisons))
    map(keys) do (source, category)
        rows = filter(c -> c.source == source && c.category == category, comparisons)
        absolute = [abs(c.actual - c.expected) for c in rows]
        # This symmetric relative error is zero for two exact zeros; it stays
        # interpretable for tiny positive KL values without an arbitrary floor.
        relative = [a == 0 ? 0. : a / max(abs(c.actual), abs(c.expected))
                    for (a, c) in zip(absolute, rows)]
        (; source, category, comparisons=length(rows),
           max_absolute_difference=maximum(absolute), max_relative_difference=maximum(relative),
           atol=first(rows).atol, rtol=first(rows).rtol,
           passed=all(comparison_passes, rows))
    end
end

function write_comparison_report(path, summary)
    ispath(path) && error("Comparison report already exists")
    open(path, "w") do io
        println(io, "source,category,comparisons,max_absolute_difference,max_relative_difference,atol,rtol,passed")
        for row in summary
            println(io, join(values(row), ','))
        end
    end
end
