# Finite-horizon inference for weak OU mean reversion

How informative can confidence sets for mean reversion be from one finite
observation window when drift and diffusion scale are unknown? This repository
provides a Julia implementation and numerical verification of an exact scalar
Ornstein–Uhlenbeck likelihood, including irregular observation times and the
Brownian-with-drift boundary.

The model, conditional on a fixed observed initial state, is

\[
 dX_t=(a-\kappa X_t)\,dt+\sigma\,dW_t,
 \qquad a\in\mathbb R,\quad\kappa\geq0,\quad\sigma>0.
\]

At positive kappa the long-run mean is a/kappa; that mean is unidentified at
zero. Observation times are deterministic or exogenous. Transitions are exact
Gaussian transitions, with no Euler approximation or stationary initial density.

## Current scope

The code implements stable transition coefficients, exact simulation, conditional
log likelihood, analytic nuisance profiling, bounded profile fitting, a
chronological split-profile statistic and a restricted continuous-path/sampled
KL calculation. Deterministic cases are checked against frozen Python and
independent base-R formulas. Julia is the canonical implementation.

This is a **reproduction and numerical technical study**. It does not establish a
new inference method, an efficiency advantage, or a completed confirmatory study.
The split construction specializes existing universal inference. Its exact-model
mathematical validity does not certify every floating-point evaluation. The
bounded optimizer is not a certified global MLE. No continuum confidence-set
endpoints, calibrated grid-bootstrap comparison or confidence sequence is claimed.

## Reproduction

Use Julia 1.12.5 (the recorded validation version). Dependencies are Julia standard
libraries; no general SDE solver is required. From the repository root:

```sh
export JULIA_DEPOT_PATH="$PWD/.julia-depot"
export JULIA_NUM_THREADS=1 JULIA_NUM_PRECOMPILE_TASKS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
julia --startup-file=no --project=. scripts/run.jl crosscheck
julia --startup-file=no --project=. scripts/run.jl smoke
```

The public test suite consumes compact deterministic reference fixtures and
requires no Python installation. See `test/fixtures/README.md` for reference
versions, provenance and tolerances. The crosscheck command reports absolute and
relative numerical differences. Fresh runs write unique `results/` directories
with environment files, source hashes, configurations, seeds, warnings and runtime.
`make setup`, `make test`, `make crosscheck` and `make smoke` are equivalent shortcuts.

For a slightly larger exploratory run:

```sh
julia --startup-file=no --project=. scripts/run.jl pilot --reps 100
```

This remains DEVELOPMENT evidence. Never relabel its seeds as confirmation.

## Experiments and interpretation

The compact smoke experiment uses 32 independent trajectories in 16 cells:
T=1, X0=a=0, sigma=1; kappa in {0, 0.1, 1, 4}; 64 or 256 transitions; regular
or alternating deterministic gaps. Both a and sigma are unknown to inference.
It compares truth membership and zero exclusion for the split-profile rule and
an explicitly uncalibrated chi-square likelihood-ratio diagnostic. It is a
software smoke test, not a power or coverage study. Different resolutions are
not nested paths, so this is not a paired infill experiment.

The deterministic information calculation uses the narrower known-a=0,
known-sigma, X0=0 submodel. At c=kappa*T=0.1, continuous-path KL against Brownian
motion is approximately 0.0023413441 and Pinsker gives a level-0.05 power upper
bound of approximately 0.0842151. Discrete observation cannot increase KL.
These elementary calculations are not asserted to be novel.

The earlier development pilot found severe conservativeness of the single-split
rule and poor truth membership for the uncalibrated LR diagnostic. Negative
findings and their scope are retained in `docs/findings.md`; high coverage alone
does not imply informative inference.

## Layout

- `src/`: exact model, likelihood, profiling, simulation, inference and information.
- `test/`: Julia tests and deterministic reference fixtures.
- `scripts/`: bounded development runner and numerical crosscheck.
- `reference/r/`: small independent base-R checks.
- `docs/`: theory, methodology, protocol, findings and literature context.
- `results/`: compact reviewed outputs; new raw runs are ignored by Git.

The next milestone is faithful grid-bootstrap replication, followed by confidence
set geometry and paired fixed-span versus longer-span experiments. Unresolved
or unbounded tails must remain visible rather than becoming artificial endpoints.

## Citation and license

Please cite the software using `CITATION.cff` and cite the underlying statistical
methods when using them. This repository is not a published paper. The source
code and original documentation are distributed under the MIT license; see
`LICENSE`. Literature is referenced, not redistributed. No author implementation
from a third-party paper is bundled. See `docs/methodology.md` for provenance.
