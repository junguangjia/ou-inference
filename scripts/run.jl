using Dates, SHA, TOML, UUIDs, LinearAlgebra
BLAS.set_num_threads(1)
const ROOT = normpath(joinpath(@__DIR__, ".."))

function source_hashes()
    files = ["Project.toml", "Manifest.toml"]
    for folder in ("src", "test", "scripts", "reference/r")
        for (dir, _, names) in walkdir(joinpath(ROOT, folder)), name in names
            any(ext -> endswith(name, ext), (".jl", ".csv", ".R", ".json", ".toml")) || continue
            push!(files, relpath(joinpath(dir, name), ROOT))
        end
    end
    Dict(path => bytes2hex(sha256(read(joinpath(ROOT, path)))) for path in sort(files) if isfile(joinpath(ROOT,path)))
end

function main(args)
    task = isempty(args) ? "smoke" : args[1]
    task in ("test", "smoke", "pilot", "crosscheck") || error("Usage: run.jl test|smoke|pilot|crosscheck [--reps N]")
    reps = task == "pilot" ? 100 : 2
    if length(args) > 1
        length(args) == 3 && args[2] == "--reps" && task in ("smoke", "pilot") || error("Invalid arguments")
        reps = parse(Int, args[3])
    end
    runid = Dates.format(now(UTC), "yyyymmddTHHMMSS") * "Z-julia-" * task * "-" * first(string(uuid4()),8)
    out = joinpath(ROOT,"results",runid); mkpath(out)
    source = source_hashes()
    head = try strip(read(pipeline(`git -C $ROOT rev-parse --verify HEAD`; stderr=devnull),String)) catch; "uncommitted" end
    metadata = Dict{String,Any}("run_id"=>runid, "task"=>task, "status"=>"running", "purpose"=>"DEVELOPMENT",
        "julia_version"=>string(VERSION), "julia_threads"=>Threads.nthreads(), "blas_threads"=>BLAS.get_num_threads(),
        "source_hashes"=>source, "git_commit"=>head, "repetitions_per_cell"=>reps, "timeout_seconds"=>180)
    for file in ("Project.toml", "Manifest.toml"); cp(joinpath(ROOT,file),joinpath(out,file)); end
    cmd = if task == "test"
        `$(Base.julia_cmd()) --startup-file=no --project=$ROOT $(joinpath(ROOT,"test/runtests.jl"))`
    elseif task == "crosscheck"
        `$(Base.julia_cmd()) --startup-file=no --project=$ROOT $(joinpath(ROOT,"scripts/crosscheck_python.jl"))`
    else
        # Include rather than package the small development experiment.
        script = "include(" * repr(joinpath(ROOT,"scripts/pilot.jl")) * "); pilot(" * repr(joinpath(out,"experiment")) * ", PilotConfig(repetitions=" * string(reps) * "))"
        `$(Base.julia_cmd()) --startup-file=no --project=$ROOT -e $script`
    end
    metadata["command"] = task in ("test","crosscheck") ? "julia --startup-file=no --project=. " * (task=="test" ? "test/runtests.jl" : "scripts/crosscheck_python.jl") : "julia --startup-file=no --project=. scripts/run.jl $task --reps $reps"
    env = [name=>"1" for name in ("JULIA_NUM_THREADS","OPENBLAS_NUM_THREADS","OMP_NUM_THREADS","MKL_NUM_THREADS","VECLIB_MAXIMUM_THREADS")]
    report = joinpath(out,"run.toml")
    open(io->TOML.print(io,metadata;sorted=true),report,"w")
    println("Run directory: results/",runid); flush(stdout)
    started = time()
    code = 1
    process = nothing
    try
        code = open(joinpath(out,"output.log"),"w") do io
            # A new process group contains only this run and its descendants.
            owned = Cmd(addenv(cmd,env...); detach=true)
            process = run(pipeline(owned; stdout=io,stderr=io);wait=false)
            outcome = timedwait(()->process_exited(process),180;pollint=0.1)
            if outcome == :timed_out
                group = -getpid(process)
                ccall(:kill, Cint, (Cint, Cint), group, Base.SIGTERM)
                timedwait(()->process_exited(process),2;pollint=0.05)
                ccall(:kill, Cint, (Cint, Cint), group, Base.SIGKILL)
                metadata["timeout"] = true
                return 124
            end
            wait(process)
            process.exitcode
        end
    catch err
        if !isnothing(process) && !process_exited(process)
            group = -getpid(process)
            ccall(:kill, Cint, (Cint, Cint), group, Base.SIGTERM)
            timedwait(()->process_exited(process),2;pollint=0.05)
            ccall(:kill, Cint, (Cint, Cint), group, Base.SIGKILL)
        end
        metadata["error_category"] = string(nameof(typeof(err)))
        metadata["error"] = sprint(showerror,err)
        code = 1
    finally
        metadata["source_unchanged_during_run"] = source == source_hashes()
        if !metadata["source_unchanged_during_run"] && code == 0
            code = 2
            metadata["error_category"] = "source_changed_during_run"
        end
        metadata["status"] = code==0 ? "passed" : "failed"
        metadata["exit_code"] = code
        metadata["runtime_seconds"] = time()-started
        open(io->TOML.print(io,metadata;sorted=true),report,"w")
    end
    logfile = joinpath(out,"output.log")
    isfile(logfile) && print(read(logfile,String))
    println("Status: ",metadata["status"])
    return code
end
exit(main(ARGS))
