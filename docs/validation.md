# Numerical verification

Validation date: 2026-09-28 UTC. Julia 1.12.5, Statistics 1.11.5;
Python reference 3.12.9 with NumPy 2.3.5 and SciPy 1.17.0;
base R 4.5.3. No third-party author implementation is used as an oracle.
The Julia code is canonical; the Python numerical source is frozen.

The Julia suite passed **2,468 assertions**, including **2,236 cross-language
scalar comparisons**. These are assertion counts, not independent statistical
replications. Deterministic regular/irregular cases fix observations, times,
parameters and innovations. Ten direct R nuisance optimizations also converge.
Fresh Python/R generation reproduces all 11 saved reference outputs byte-for-byte.

| Comparison group | Scalars | Maximum absolute difference | Maximum symmetric relative difference |
|---|---:|---:|---:|
| Closed forms and fixed diagnostics | 2,158 | 3.553e-14 | 5.079e-7 |
| Bounded objective and LR | 24 | 3.242e-14 | 6.110e-14 |
| Bounded parameters and predictive/split scores | 24 | 4.057e-6 | 1.598e-6 |
| Direct nuisance parameter optimization | 20 | 3.193e-7 | 7.956e-7 |
| Direct nuisance optimized objective | 10 | 6.359e-13 | 6.056e-14 |

The two maxima in a row need not come from the same scalar. In the first row,
the relative maximum is a KL of order 1e-20, where frozen references lose
precision by subtraction; it is not a discrepancy of that size in ordinary
likelihoods. Detailed values and fixed tolerances are in
`results/reviewed/comparison.csv` and `test/fixtures/README.md`. No tolerance was
relaxed after observing a failure.

## Coverage of the tests

The suite checks exact kappa=0 limits, continuity, semigroup identities, positive
variance, regular/generic-grid agreement, time and affine-state transformations,
likelihood decomposition, analytic nuisance domination and direct optimization,
training-prefix measurability, degenerate supremum, explicit RNG reproducibility,
search-cap/tail reporting and numerical failures. No cap is a confidence endpoint.

Simulation moment checks use 12,000 independent trajectories in each of six
small cells (72,000 short paths total), with six-standard-error bounds. They
validate the simulator and are not a 72,000-path inference study. The compact
inference smoke uses only 32 trajectories and has zero recorded failures.
Wilson intervals and MCSEs remain reported even when observed rates are zero/one.

## Tiny-parameter correction

The frozen sampled KL forms u=v/Delta-1, losing its O(kappa*Delta) term by
cancellation. Julia instead expands u directly for small kappa*Delta, then
computes u-log1p(u) stably. At kappa=1e-16 on [0,1], the former expression is
about 3.0815e-33 while the correct leading term and path KL are about 2.5e-33.
At kappa=1e-18 the old expression can round to zero. The frozen references remain
unchanged to preserve the discrepancy. Fourteen independent 256-bit Gaussian
chain calculations pass with atol=0 and rtol=1e-12 for the repaired Julia formula.

Julia's local golden-section search differs from Python's bounded scalar search;
parameter and predictive-score tolerances reflect their sensitivity. The maximum
objective difference is much smaller. Neither search is globally certified.

## What is established

The formulas have explicit derivations, and the tested numerical routes agree
within declared tolerances, subject to the disclosed small-KL correction.
Neither tests nor empirical membership rates prove novelty, uniform empirical
coverage, globally optimal fitting, conservative floating-point denominator
bounds, or certified confidence endpoints. These remain separate research tasks.

Run the README commands to produce fresh verification and smoke outputs.
Environment manifests and source hashes accompany the compact archived Julia run.
