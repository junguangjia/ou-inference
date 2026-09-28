using SHA, Printf, TOML, OUInference

const REPORT_ROOT = normpath(joinpath(@__DIR__, ".."))
const REPORT_DATA = joinpath(REPORT_ROOT, "results", "reviewed", "julia-development")
const REPORT_SNAPSHOT_SHA256 = Dict(
    "Project.toml" => "5ca8c7859f0be63295080bdd08bf4a8fe323950fc94d7aa6f959d9b603b4be98",
    "Manifest.toml" => "3360c3dcb0d0685255efac07c1b35ea138511b262f133bbdafa7e15043ac3fc2",
    "run.toml" => "2452b0a05715dfffc8e6b65ac8a896a8dc3bce3076648fd120d36aa008a0c24b",
    "metadata.toml" => "7b823942278ceee31e9c0af3a4c7dc20f8701a1765378a79aa993401f2d756cc",
    "replicates.csv" => "2fdf4186ceeaa83dd839cd58bb5e3674765239bf1b2758667b708ab12559ecaa",
    "summary.csv" => "a4aae14a829baaf44c22f5199a49b73da25988bb8646e97a7cefe17242e832b7",
    "information.csv" => "4bb28db0f582248680b7a3ae4774ec6e03f11e1343e38495b448a3ba3ebad09d")

function report_rows(path)
    lines = readlines(path)
    header = split(first(lines), ',')
    length(unique(header)) == length(header) || error("Duplicate CSV column")
    rows = [split(line, ',') for line in lines[2:end] if !isempty(line)]
    all(length(row) == length(header) for row in rows) || error("Invalid CSV shape")
    [Dict(zip(header, row)) for row in rows]
end

function validate_report_inputs(summary, replicates, metadata, run, info)
    # This report describes one archived development experiment. Changed inputs
    # require a fresh interpretation, not silent reuse of its fixed prose.
    for (name, expected) in REPORT_SNAPSHOT_SHA256
        bytes2hex(sha256(read(joinpath(REPORT_DATA, name)))) == expected ||
            error("The fixed report snapshot changed; re-review the report: " * name)
    end
    expected_run = "20260928T030948Z-julia-pilot-a8881b95"
    base_seed = 2026092803
    kappas = (0.0, 0.1, 1.0, 4.0)
    metrics = ("lr_contains_truth", "lr_excludes_zero", "split_contains_truth", "split_excludes_zero")
    metadata["status"] == "DEVELOPMENT" && metadata["failures"] == 0 || error("Revisit report interpretation")
    metadata["trajectories"] == 1600 && metadata["replications_per_cell"] == 100 || error("Unexpected replication counts")
    metadata["seed"] == base_seed && metadata["julia_version"] == "1.12.5" || error("Unexpected experiment identity")
    metadata["T"] == 1.0 && metadata["a"] == 0.0 && metadata["sigma"] == 1.0 && metadata["x0"] == 0.0 ||
        error("Unexpected generating parameters")
    metadata["alpha"] == 0.05 && metadata["kappa"] == collect(kappas) && metadata["n"] == [64, 256] ||
        error("Unexpected inference/design parameters")
    metadata["rng"] == "Xoshiro; fresh RNG with recorded seed for each trajectory" || error("Unexpected random generator")
    metadata["schedules"] == ["regular", "alternating normalized gaps 0.25 and 1.75"] || error("Unexpected schedules")
    metadata["methods"] == ["uncalibrated chi-square LR diagnostic", "chronological split profile e-value"] ||
        error("Unexpected methods")
    run["run_id"] == expected_run && run["task"] == "pilot" && run["purpose"] == "DEVELOPMENT" ||
        error("Unexpected run record")
    run["status"] == "passed" && run["exit_code"] == 0 && run["source_unchanged_during_run"] === true ||
        error("Archived run did not complete with stable source")
    run["julia_version"] == "1.12.5" && run["repetitions_per_cell"] == 100 &&
        run["julia_threads"] == 1 && run["blas_threads"] == 1 || error("Unexpected run environment")
    length(summary) == 64 && length(replicates) == 1600 || error("Unexpected report experiment")

    implementation = ["Project.toml", "Manifest.toml", "scripts/pilot.jl"]
    append!(implementation, [joinpath("src", name) for name in sort(readdir(joinpath(REPORT_ROOT, "src")))
                             if endswith(name, ".jl")])
    for path in implementation
        expected = get(run["source_hashes"], path, nothing)
        !isnothing(expected) && bytes2hex(sha256(read(joinpath(REPORT_ROOT, path)))) == expected ||
            error("Current implementation/environment differs from the archived run: " * path)
    end
    for name in ("Project.toml", "Manifest.toml")
        read(joinpath(REPORT_DATA, name)) == read(joinpath(REPORT_ROOT, name)) ||
            error("Archived environment copy differs: " * name)
    end

    # The saved row order fixes the fresh-RNG seed mapping. Verify every path,
    # including diagnostic flags, before using any summary or fixed narrative.
    index = 0
    for design in ("regular", "alternating"), k in kappas, n in (64, 256), rep in 1:100
        index += 1
        r = replicates[index]
        r["design"] == design && parse(Float64, r["kappa"]) == k &&
            parse(Int, r["n"]) == n && parse(Int, r["replicate"]) == rep || error("Unexpected trajectory design/order")
        parse(Int, r["seed"]) == base_seed + index || error("Unexpected trajectory seed")
        all(parse(Float64, r[name]) == value for (name, value) in
            (("T", 1.0), ("a", 0.0), ("sigma", 1.0), ("x0", 0.0))) || error("Unexpected trajectory parameters")
        r["status"] == "completed" && r["failure"] == "none" || error("Unaccounted trajectory failure")
        r["fit_status"] == "bounded_search_completed" && r["training_status"] == "bounded_search_completed" ||
            error("Report must retain fitting warnings")
        all(parse(Int, r[name]) == 0 for name in
            ("fit_optimizer_failures", "fit_numerical_failures", "training_optimizer_failures",
             "training_numerical_failures", "fit_warning", "training_warning")) || error("Unexpected numerical warning")
        isapprox(parse(Float64, r["fit_cap"]), 200.0; atol=1e-10, rtol=0) &&
            isapprox(parse(Float64, r["training_cap"]), 400.0; atol=1e-10, rtol=0) || error("Unexpected search cap")
        estimate = parse(Float64, r["kappa_hat"])
        isfinite(estimate) && 0 <= estimate < parse(Float64, r["fit_cap"]) * (1 - 1e-7) || error("Invalid or capped estimate")
        all(parse(Int, r[metric]) in (0, 1) for metric in metrics) || error("Nonbinary outcome")
        for (score, metric, exclude) in (("log_e_truth", "split_contains_truth", false), ("log_e_zero", "split_excludes_zero", true))
            value = parse(Float64, r[score])
            (isfinite(value) || value == -Inf) || error("Invalid split score")
            expected = exclude ? Int(value > -log(0.05)) : Int(value <= -log(0.05))
            parse(Int, r[metric]) == expected || error("Split outcome disagrees with score")
        end
        k != 0.0 || all(parse(Int, r[inside]) + parse(Int, r[outside]) == 1 for (inside, outside) in
            (("lr_contains_truth", "lr_excludes_zero"), ("split_contains_truth", "split_excludes_zero"))) ||
            error("Null membership and exclusion are inconsistent")
    end

    # Recompute all 64 binomial summaries from all 1,600 trajectories. Absolute
    # tolerance 2e-14 covers Float64 evaluation/serialization, not statistical error.
    z = 1.959963984540054
    for design in ("regular", "alternating"), k in kappas, n in (64, 256), metric in metrics
        rows = filter(r -> r["design"] == design && parse(Float64, r["kappa"]) == k && parse(Int, r["n"]) == n, replicates)
        length(rows) == 100 || error("Incomplete trajectory cell")
        s = only(filter(r -> r["design"] == design && parse(Float64, r["kappa"]) == k &&
                        parse(Int, r["n"]) == n && r["metric"] == metric, summary))
        S = sum(parse(Int, r[metric]) for r in rows)
        parse(Float64, s["T"]) == 1.0 && parse(Int, s["attempted"]) == 100 && parse(Int, s["completed"]) == 100 &&
            parse(Int, s["failures"]) == 0 && parse(Int, s["successes"]) == S || error("Summary counts disagree with trajectories")
        parse(Int, s["fit_warnings"]) == 0 && parse(Int, s["training_warnings"]) == 0 || error("Summary warning mismatch")
        p = S / 100
        denominator = 1 + z^2 / 100
        center = (p + z^2 / 200) / denominator
        half = z * sqrt(p * (1 - p) / 100 + z^2 / 40000) / denominator
        for (name, value) in (("rate_lower", p), ("rate_upper", p), ("mcse", sqrt(p * (1 - p) / 100)),
                              ("wilson_lower", max(0.0, center - half)), ("wilson_upper", min(1.0, center + half)))
            isapprox(parse(Float64, s[name]), value; atol=2e-14, rtol=0) || error("Stale/incorrect summary column: " * name)
        end
    end

    # The report's information table is for the separately stated restricted
    # model. Verify its fixed grid and formulas without simulating new paths.
    length(info) == 12 || error("Unexpected information table")
    for c in (0.1, 1.0, 4.0), n in (8, 32, 128, 2048)
        r = only(filter(r -> parse(Float64, r["c"]) == c && parse(Int, r["n"]) == n, info))
        for (name, value) in (("discrete_KL", kl_discrete(c, collect(range(0.0, 1.0; length=n+1)))),
                              ("continuous_KL", kl_continuous(c)), ("level_05_power_bound", pinsker_power_bound(c)))
            isapprox(parse(Float64, r[name]), value; atol=1e-12, rtol=1e-12) || error("Information table mismatch: " * name)
        end
    end
    return nothing
end

function build_report()
    summary = report_rows(joinpath(REPORT_DATA, "summary.csv"))
    replicates = report_rows(joinpath(REPORT_DATA, "replicates.csv"))
    metadata = TOML.parsefile(joinpath(REPORT_DATA, "metadata.toml"))
    run = TOML.parsefile(joinpath(REPORT_DATA, "run.toml"))
    info = report_rows(joinpath(REPORT_DATA, "information.csv"))
    validate_report_inputs(summary, replicates, metadata, run, info)
    cell(design, n, k, metric) = only(filter(summary) do r
        r["design"] == design && parse(Int,r["n"]) == n && parse(Float64,r["kappa"]) == k && r["metric"] == metric
    end)
    replacements = Dict{String,String}()
    names = Dict(("regular",64)=>"REGULAR64", ("regular",256)=>"REGULAR256",
                 ("alternating",64)=>"ALTERNATING64", ("alternating",256)=>"ALTERNATING256")
    for ((design,n), token) in names
        lines = ["index lr lrminus lrplus split splitminus splitplus"]
        for (index,k) in enumerate((0.0,0.1,1.0,4.0))
            vals = Float64[]
            for metric in ("lr_contains_truth","split_contains_truth")
                r=cell(design,n,k,metric)
                p=parse(Float64,r["rate_lower"])
                append!(vals,[p,p-parse(Float64,r["wilson_lower"]),parse(Float64,r["wilson_upper"])-p])
            end
            push!(lines,string(index)*" "*join((@sprintf("%.17g",v) for v in vals),' '))
        end
        replacements[token]=join(lines,'\n')
    end
    lines=String[]
    for k in (0.0,0.1,1.0,4.0)
        selected=filter(r->r["design"]=="regular" && parse(Int,r["n"])==256 && parse(Float64,r["kappa"])==k,replicates)
        khat=sum(parse(Float64,r["kappa_hat"]) for r in selected)/length(selected)
        rates=[parse(Float64,cell("regular",256,k,metric)["rate_lower"]) for metric in
            ("lr_contains_truth","split_contains_truth","lr_excludes_zero","split_excludes_zero")]
        push!(lines,@sprintf("%.1f & %.3f & %.2f & %.2f & %.2f & %.2f",k,khat,rates[1],rates[2],rates[3],rates[4]) * " " * repeat(string(Char(92)),2))
    end
    replacements["RESULTS_TABLE"]=join(lines,'\n')
    lines=String[]
    for c in (0.1,1.0,4.0)
        r=only(filter(r->parse(Float64,r["c"])==c && parse(Int,r["n"])==8,info))
        push!(lines,@sprintf("%.1f & %.9f & %.9f & %.6f",c,
            parse(Float64,r["discrete_KL"]),parse(Float64,r["continuous_KL"]),parse(Float64,r["level_05_power_bound"])) * " " * repeat(string(Char(92)),2))
    end
    replacements["INFORMATION_TABLE"]=join(lines,'\n')
    sourcepaths=["Project.toml","Manifest.toml","scripts/pilot.jl"]
    append!(sourcepaths,[joinpath("src",name) for name in sort(readdir(joinpath(REPORT_ROOT,"src"))) if endswith(name,".jl")])
    append!(sourcepaths,[joinpath("results/reviewed/julia-development",n) for n in ("summary.csv","replicates.csv","information.csv","metadata.toml","run.toml")])
    hashes=Dict(path=>bytes2hex(sha256(read(joinpath(REPORT_ROOT,path)))) for path in sourcepaths)
    fingerprint=bytes2hex(sha256(join((path*" "*hashes[path]*"\n" for path in sort(sourcepaths)))))
    replacements["SOURCE_DIGEST"]=fingerprint
    replacements["RUN_ID"]=run["run_id"]
    template=read(joinpath(REPORT_ROOT,"latex/report-template.tex"),String)
    for (key,value) in replacements
        token="@@"*key*"@@"
        occursin(token,template) || error("Unused report token: "*key)
        template=replace(template,token=>value)
    end
    occursin(r"@@[A-Z0-9_]+@@",template) && error("Unfilled report token")
    target=joinpath(REPORT_ROOT,"latex/ou-inference-report.tex")
    write(target,template)
    manifest=Dict("purpose"=>"Report source and data provenance", "stage"=>"DEVELOPMENT", "julia_version"=>string(VERSION),
        "fingerprint"=>fingerprint,"inputs"=>hashes,"template_sha256"=>bytes2hex(sha256(read(joinpath(REPORT_ROOT,"latex/report-template.tex")))),
        "builder_sha256"=>bytes2hex(sha256(read(@__FILE__))),"tex_sha256"=>bytes2hex(sha256(read(target))))
    open(io->TOML.print(io,manifest;sorted=true),joinpath(REPORT_ROOT,"latex/report-manifest.toml"),"w")
    println("Built latex/ou-inference-report.tex from 1,600 saved DEVELOPMENT trajectories.")
    println("Data/source fingerprint: ",fingerprint)
end

build_report()
