# Saved Julia development experiment

This is the immutable input snapshot for `latex/ou-inference-report.tex`:
run `20260928T030948Z-julia-pilot-a8881b95`, with 1,600 independent trajectories
in 16 cells (100 per cell). It is exploratory DEVELOPMENT evidence, not a
confirmation run.

The design uses fixed `T=1`, `x0=a=0`, `sigma=1`, four reversion values
`{0, 0.1, 1, 4}`, two transition counts `{64, 256}`, and regular or alternating
exogenous gaps. Inference treats both `a` and `sigma` as unknown. The chronological
split uses half the transitions, with `alpha=0.05`. Paths across resolutions and
schedules are independent rather than nested. Each trajectory has its own Julia
Xoshiro stream; its recorded seed is base `2026092803` plus the trajectory index.

- `replicates.csv`: every attempted trajectory, including fitted kappa,
  statistics, membership/exclusion indicators and warning fields.
- `summary.csv`: four binary metrics per cell, with Monte Carlo standard errors
  and pointwise Wilson intervals. All attempts remain in the denominators.
- `information.csv`: deterministic restricted KL and power-envelope calculations.
- `metadata.toml`: experiment design, base seed, status and failure count.
- `run.toml`: run identifier, source hashes and runtime record.
- `Project.toml`, `Manifest.toml`: recorded Julia environment.

The run preceded the initial public commit and honestly records its Git state as
`uncommitted`. Its saved implementation, fixture and environment hashes were
checked against public source commit `d08dc35`. This is a content match, not a
claim that the run was executed from that commit.

`julia --startup-file=no --project=. scripts/build_report.jl` validates this
snapshot and regenerates the report source and provenance manifest. New
experiments must use new run directories rather than overwrite this snapshot.
