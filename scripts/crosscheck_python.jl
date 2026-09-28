using OUInference
using Dates
using SHA
using TOML
using UUIDs

include(joinpath(@__DIR__, "..", "test", "cross_language_helpers.jl"))

function crosscheck_main(args)
    root = dirname(@__DIR__)
    regenerate = "--regenerate" in args
    filtered = filter(!=("--regenerate"), args)
    if !isempty(filtered) && !(length(filtered) == 2 && filtered[1] == "--out")
        error("Usage: julia --project=. scripts/crosscheck_python.jl [--regenerate] [--out new_directory]")
    end
    runid = Dates.format(now(UTC), dateformat"yyyymmddTHHMMSSZ") * "-crosscheck-" * string(uuid4())[1:8]
    out = isempty(filtered) ? joinpath(root, "results", runid) : abspath(filtered[2])
    ispath(out) && error("Output directory must be new")
    mkpath(out)
    fixtures = joinpath(root, "test", "fixtures", "v1")
    if regenerate
        # Optional private-reference audit. Public tests do not need Python/R.
        python = joinpath(root, ".venv", "bin", "python")
        isfile(python) || error("Project-local Python runtime unavailable")
        isfile(joinpath(root, "reference", "python_v1", "src", "ouinfer", "core.py")) ||
            error("Frozen Python reference unavailable; use committed fixtures")
        isnothing(Sys.which("Rscript")) && error("Base R unavailable")
        fixtures = joinpath(out, "regenerated")
        withenv("OPENBLAS_NUM_THREADS" => "1", "OMP_NUM_THREADS" => "1", "MKL_NUM_THREADS" => "1") do
            run(`$python $(joinpath(@__DIR__, "build_reference_fixtures.py")) --out $fixtures`)
            run(`Rscript --vanilla $(joinpath(root, "reference", "r", "crosscheck_core.R")) $(joinpath(fixtures, "observations.csv")) $(joinpath(fixtures, "r"))`)
        end
    end
    started = time()
    comparisons = cross_language_comparisons(fixtures)
    summary = comparison_summary(comparisons)
    write_comparison_report(joinpath(out, "comparison.csv"), summary)
    passed = all(comparison_passes, comparisons)
    hashes = Dict(relpath(joinpath(dir, name), fixtures) => bytes2hex(sha256(read(joinpath(dir, name))))
                  for (dir, _, names) in walkdir(fixtures) for name in names if endswith(name, ".csv"))
    report = Dict("status" => passed ? "passed" : "failed", "julia_version" => string(VERSION),
                  "comparisons" => length(comparisons), "regenerated" => regenerate,
                  "elapsed_seconds" => time() - started, "fixture_sha256" => hashes,
                  "scope" => "Deterministic synthetic data; numerical validation, not proofs or coverage certification",
                  "relative_error" => "abs(actual-expected)/max(abs(actual),abs(expected)); zero for two zeros",
                  "max_absolute_difference" => maximum(r.max_absolute_difference for r in summary),
                  "max_relative_difference" => maximum(r.max_relative_difference for r in summary))
    open(joinpath(out, "comparison.toml"), "w") do io
        TOML.print(io, report; sorted=true)
    end
    println("Numerical cross-check: ", report["status"], " (", length(comparisons), " comparisons)")
    println("Maximum absolute difference: ", report["max_absolute_difference"])
    println("Maximum symmetric relative difference: ", report["max_relative_difference"])
    println("Report: ", relpath(joinpath(out, "comparison.csv"), root))
    passed || error("Cross-language discrepancies exceed predetermined tolerances")
end

crosscheck_main(ARGS)
