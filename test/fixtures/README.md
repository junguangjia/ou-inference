# Deterministic numerical references

The `v1` directory contains synthetic regular and irregular observation schedules,
fixed innovations, and numerical references. No observed data or coursework is
included. The generating model is kappa=0.2, a=0.3, sigma=0.7, X0=-0.4 over T=2,
with 20 transitions. Candidate kappa values are 0, 1e-10, 0.1, 1 and 7.

`python_*.csv` was calculated from the frozen validated Python core, whose SHA-256
is recorded in `python_provenance.json`. That file records exact environment
versions, generation parameters and CSV hashes. `r/*.csv` was computed separately
by `reference/r/crosscheck_core.R` using base R; its version is in `r_version.txt`.
The R likelihood uses `dnorm`, its continuous-path KL uses numerical integration
of expected quadratic drift energy, and its direct nuisance fit uses BFGS on
(a, log(sigma2)) from a fixed starting point with an analytic score.

The public Julia tests consume these files without Python or R. The optional
private-reference command `julia --project=. scripts/crosscheck_python.jl
--regenerate` requires the original frozen snapshot and the project Python
environment. It creates new outputs and does not replace committed fixtures.
Fresh R checks can also be run with `Rscript --vanilla
reference/r/crosscheck_core.R test/fixtures/v1/observations.csv NEW_DIRECTORY`.

## Tolerances declared before comparison

Every scalar passes if `abs(actual-reference) <= atol + rtol*abs(reference)`.

| Quantity | atol | rtol | Reason |
|---|---:|---:|---|
| Transition, conditional moments, fixed-nuisance likelihood, analytic profile, KL | 1e-10 | 1e-10 | Floating-point elementary functions and summation |
| Bounded fitted likelihood and selected LR statistic | 1e-8 | 1e-8 | Different scalar optimization algorithms |
| Bounded fit parameters, predictive score and split log e-value | 2e-5 | 2e-5 | Parameters and out-of-sample scores are more sensitive than maximized likelihood |
| Direct numerical nuisance estimates versus analytic estimates | 5e-6 | 5e-6 | BFGS stopping and parameter sensitivity |
| Direct numerical nuisance likelihood versus analytic profile | 1e-9 | 1e-9 | Smooth objective at its optimum |

Reports give maximum absolute and symmetric relative differences by category;
relative error is `abs(actual-reference)/max(abs(actual),abs(reference))`, defined
as zero for two exact zeros. These diagnostics do not certify a global likelihood
maximum or confidence endpoints. No tolerance was changed after executing tests.

The seeded moment tests use 12,000 independent trajectories per cell, six cells,
with six-standard-error bounds for the mean and unbiased sample variance. Their
development seed formula is `2026092803 + 10*design_id + kappa_id`; design and
kappa IDs are one-based. These are software tests, not confirmation experiments.
Cross-language simulation uses supplied innovations because different language
RNG streams need not match. `sha256.csv` protects every numerical reference file.

An additional analytic regression checks kappa=1e-16 and 1e-18: the frozen
Python discrete KL can lose the `v/gap-1` term through cancellation. Julia uses
its small-argument expansion and agrees with KL = kappa^2/4 + O(kappa^3) at
T=1 on the tested grids. The Python snapshot and its fixture values are retained
unchanged. The same cancellation causes an approximately 5.1e-7 relative
difference in the kappa=1e-10 fixture KL, whose absolute magnitude is about
1e-20. A separate 256-bit BigFloat Gaussian-chain calculation tests relative
accuracy at 1e-18 through 7 with atol=0 and rtol=1e-12, declared before running
that check. This numerical repair does not introduce a new statistical method.
