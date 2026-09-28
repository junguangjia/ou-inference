# Methodology and implementation scope

The target is uncertainty in the mean-reversion parameter of
\(dX_t=(a-\kappa X_t)dt+\sigma dW_t\), conditional on a fixed initial state,
with \(a\in\mathbb R\), \(\kappa\geq0\), and \(\sigma>0\). Observation times
are deterministic or exogenous in the sense specified in
[theory.md](theory.md). The canonical implementation is Julia. Base R supplies
selected independent numerical checks; the validated Python implementation is a
frozen comparison reference, not a parallel research implementation.

## Mathematical components

| Component | Definition and purpose |
|---|---|
| Transition coefficients | Exact exponential mean and integrated variance, including the exact zero-reversion branch |
| Simulator | Sequential Gaussian transitions with an explicit random generator or supplied innovations |
| Conditional log likelihood | Product of transition densities, with no initial-state density |
| Candidate profile | Analytic maximization over unrestricted drift and positive variance |
| Bounded profile fit | Grid search and local refinement; reports the computational cap and iid-limit comparison |
| Split profile statistic | Prefix-fitted conditional density scored on the suffix, divided by the suffix nuisance supremum |
| Information functions | Continuous-path and sampled KL in the restricted zero-drift, zero-start, known-scale experiment |

The formulas and proofs in [theory.md](theory.md) determine the implementation.
There is no Euler approximation or generic SDE solver in the core model.

The Julia and base-R numerical routines implement the displayed mathematical
formulas; no third-party author implementation is incorporated. The conditional
split construction follows Wasserman, Ramdas and Balakrishnan,
[*Universal Inference*](https://doi.org/10.1073/pnas.1922664117) (2020), with the
version and relevant sections recorded in the literature map. The Gaussian
likelihood calculations are standard. Hansen's grid bootstrap and the
Lui–Xiao–Yu continuous-time modification are literature baselines to reproduce,
not procedures already included in this codebase. Availability of author code
would not by itself establish permission to copy or redistribute it.

## What the comparisons mean

The conventional likelihood-ratio diagnostic compares a bounded fitted profile
with the profile at a candidate \(\kappa\). A conventional chi-square cutoff is
retained only as an uncalibrated comparator. Neither Wilks' theorem nor a simple
boundary mixture is assumed valid in the fixed-span weak-reversion experiment.
The bounded numerator search is not a certified global MLE; this limitation
also applies to that diagnostic statistic.

The chronological split statistic uses a normalized prefix-fitted OU density.
Approximation of this training fit affects power but does not itself invalidate
normalization. Its denominator uses the full analytic nuisance profile at the
candidate. No variance floor, bounded long-run mean, or artificial lower bound
on mean reversion is part of that profile. Degenerate training fits cannot supply
a positive-variance fitted density and are reported as failures.

The finite-sample coverage statement concerns the mathematical exact-model
construction. Numerical formula comparisons support implementation accuracy but
do not certify every floating-point evaluation or continuum confidence endpoint.
Reported pilot quantities are candidate membership and zero exclusion. Full
confidence sets, widths and unbounded-tail fractions remain future outputs.

## Numerical audit

Deterministic cross-language cases fix times, observations and parameter values.
They compare transition coefficients, conditional means/variances, likelihood,
nuisance profiles, selected likelihood ratios and information formulas using
predeclared tolerances. Identical seeds in different languages do not generally
give identical innovations; cross-language simulated paths use explicitly shared
innovations when exact path comparison is intended.

Additional checks cover the Brownian limit, semigroup identities, scaling,
regular-grid equivalence, profile domination, repeated seeded simulation,
degeneracies and search-cap reporting. Controlled moment checks use the independent
trajectory as their replication unit. Passing a finite test suite is not a proof
of the statistical guarantee or a global optimizer certificate. Actual executed
counts and discrepancies are recorded with the results, not inferred from the
presence of test code.

An independently identified edge case intentionally differs from the frozen
Python calculation: subtracting one from \(v_i/\Delta_i\) loses the leading term
for extremely small \(\kappa\Delta_i\). Julia evaluates that difference by its
Taylor expansion before forming sampled KL. Tests at \(\kappa=10^{-16}\) and
\(10^{-18}\) check the leading \(\kappa^2/4\) term on unit-horizon grids and
the data-processing bound. Separate 256-bit evaluations of the Gaussian-chain
formula check relative accuracy across the tested parameter range; ordinary
absolute fixture tolerances alone would not diagnose relative error in tiny KL
values. A small discrepancy is visible even in the \(\kappa=10^{-10}\) fixture
and is documented in the [fixture notes](../test/fixtures/README.md).
The frozen reference is preserved unchanged; the correction concerns numerical
evaluation of the same formula.

## Strong baseline and next research comparison

A faithful grid-bootstrap baseline is the next priority. Its implementation must
identify a specific paper version, statistic, null-imposed nuisance treatment,
initialization rule, resampling scheme and inversion algorithm. It must first
reproduce a published setting. Extending it to unrestricted drift at zero or
irregular sampling requires an explicit justification or a clearly labeled
adaptation. A naive percentile bootstrap must not be relabeled as this baseline.
The known asymptotic bootstrap results are not finite-sample exact guarantees.

After that reproduction, study confidence-set geometry and separate fixed-span
infill, longer-span and matched-schedule comparisons using
[protocol.md](protocol.md). The literature overlap and remaining access gaps are
documented in [literature_map.md](literature_map.md). No methodological superiority
or novelty is established by a language migration.
