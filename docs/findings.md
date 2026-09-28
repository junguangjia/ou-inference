# Findings: numerical validation and development evidence

Historical source: the preserved Python development pilot; compact outputs are in
`results/reviewed/historical-development/`. The full private run is retained unchanged.
Seed family 2026092802; 16 cells, 100 independent trajectories per cell, T=1, X0=0, a=0, sigma=1. Both a and sigma are unknown to inference. Kappa in {0,0.1,1,4}; n in {64,256}; regular and alternating deterministic gaps. Original coursework and online data were not executed.

## Selected regular-grid n=256 results

| True kappa | Mean fitted kappa | Chi-square LR truth membership | Split-e truth membership | Split-e exclusion of zero |
|---|---:|---:|---:|---:|
| 0 | 5.81890145 | 0.72 | 0.99 | 0.01 |
| 0.1 | 5.69909195 | 0.67 | 1.00 | 0.00 |
| 1 | 6.12834008 | 0.82 | 1.00 | 0.00 |
| 4 | 9.43059506 | 0.83 | 1.00 | 0.00 |

These evaluate whether the true candidate belongs to each inversion rule directly. They do not construct full confidence-set endpoints or report their widths. For LR, the cutoff is the conventional chi-square(1) 95% value; this is intentionally an UNCALIBRATED comparator in the present regime. The bounded profile optimizer found no recorded cap/tail warning in these 1,600 paths, but is not certified globally optimal.

Independent-path MCSEs for the four displayed LR membership proportions are approximately 0.04513, 0.04726, 0.03861 and 0.03775. A binomial Wilson interval at 100/100 successes is approximately [0.9630,1], not proof of perfect coverage. At zero observed exclusions out of 100 it is approximately [0,0.0370]. Full summary.csv includes Wilson intervals and MCSEs for all binary metrics.

Across all 16 cells, split-e truth membership ranged from 0.99 to 1 and zero-exclusion frequency from 0 to 0.01. Chi-square LR truth membership ranged from 0.63 to 0.88. These are development results for one narrow family, not universal performance figures or a comparison against correctly calibrated bootstrap methods.

## Interpretation

1. There is substantial short-span drift-estimation uncertainty and bias with an unknown intercept. Simply obtaining a positive fitted kappa is not strong evidence of identified reversion.
2. Increasing n at fixed T did not eliminate the behavior in this pilot. This is not a clean paired infill experiment yet: different n values use different paths, and the density/span distinction is already known.
3. The single-split nuisance-profile e-value has a mathematically valid model-based construction, but this implementation was almost unable to reject zero, even at c=4. High membership rates alone do not establish usefulness. Separate weak information from conservativeness caused by splitting and nuisance estimation.
4. The chi-square LR's failure does not show that all likelihood inference fails. The required strong baselines are grid-inverted/null-imposed bootstrap procedures with their actual assumptions.
5. No width superiority, new method, or novelty has been established. Negative informativeness results are retained explicitly.

## Restricted information check

For a=0 known, sigma known, X0=0 and c=kappa*T=0.1, the exact continuous-path KL against Brownian motion is 0.0023413441347477325. A level-0.05 test therefore has the loose power upper bound 0.08421508537726988 by Pinsker. At n=8 the exact sampled KL is 0.0023413149985251624, and at n=2048 it is 0.002341344134282626. This is the restricted submodel's information calculation, not a universal assertion about all nuisance/initial-state regimes.

## Next decision

GO for a bounded feasibility investigation; NO new-method claim at this stage. Prioritize reading the continuous-time grid-bootstrap paper, independently checking the proofs, implementing a strong calibrated baseline, and obtaining full confidence-set informativeness metrics. Then examine a fixed-span/infill efficiency result or a carefully justified numerator/split-mixture extension. Do not add many tuning components to force a win.

## Julia numerical verification

Julia 1.12.5 passed 2,468 assertions, including 2,236 deterministic scalar
comparisons with frozen Python and independent base-R outputs. Fresh regeneration
reproduced all 11 Python/R reference output files byte-for-byte. The compact
Julia smoke completed 32 independent trajectories across the same 16 scientific
cells with zero recorded failures. It uses Julia Xoshiro streams, so it is not
a claim of identical random trajectories to the historical Python pilot.
See [validation.md](validation.md) and `results/reviewed/` for numerical reports.

A numerical defect inherited from the original sampled-KL formula was found:
forming v/Delta minus one loses its first-order term at extremely small kappa.
The Julia calculation uses a direct small-argument expansion. At kappa=1e-16,
T=1 with one transition, the old expression gives about 3.0815e-33, above the
continuous-path KL of about 2.5e-33; the corrected result is about 2.5e-33.
The frozen Python and R reference values were not changed. Fourteen independent
256-bit checks support the correction with relative tolerance 1e-12 and no
absolute tolerance. This is a numerical repair, not a new statistical result.

The exact-model derivations are in [theory.md](theory.md). The profile and KL
identities are elementary derivations, the split principle is inherited from
universal inference, and implementation agreement is numerical evidence. There
is no established candidate new theorem. Full confidence-set inversion, certified
floating-point denominator bounds, bootstrap replication, nuisance sensitivity
and locked confirmation remain unresolved.
