# Reproducibility and staged experimental protocol

This protocol preserves the distinction between validation, exploratory evidence
and future confirmation. The current milestone reproduces an existing
mathematical core in Julia. It does not authorize interpreting the development
pilot as a confirmatory coverage study.

## 1. Common experiment specification

Use exact OU transitions, fixed observed \(X_0\), unrestricted \(a\), unknown
\(\sigma>0\), and \(\kappa\geq0\). Record the full sampling schedule, physical
time unit, \(T\), number of transitions \(n\), true parameters, candidate
parameters, split rule and every numerical search setting. Distinguish true
parameter values from parameters assumed known by the inference procedure.

Each run has a unique identifier and immutable configuration, explicit random
generator/seed, stage label, Julia version, Project/Manifest hashes, source hash
or commit when available, runtime, attempted trajectory count and warnings.
Use independent trajectory generators and preserve their seed mapping. Run one
worker with one BLAS thread by default. Bounded work must finish or record its
interruption, never silently drop unfinished trajectories.

## 2. Validation and compact development evidence

1. Compare deterministic Julia formulas with the frozen Python and independent R
   formulas using declared absolute and relative tolerances. Fix test cases and
   tolerances before examining discrepancies; investigate failures from formulas.
2. Check exact simulation moments, boundary limits and transformation identities.
   Separate deterministic checks from Monte Carlo checks and their uncertainty.
3. Reproduce a compact development pilot with the same scientific configuration
   as the preserved reference: \(T=1\), \(X_0=0\), \(a=0\), \(\sigma=1\),
   \(\kappa\in\{0,0.1,1,4\}\), \(n\in\{64,256\}\), and regular versus
   alternating deterministic gaps. Both drift and scale remain unknown to
   inference. Record the actual replication count; do not infer cross-language
   agreement from coincident seed integers.

The historical 100-path-per-cell pilot is exploratory. Its different values of
\(n\) did not come from nested paths. Sharing innovations across schedules is
not a shared latent continuous trajectory. These data can reveal numerical
problems or motivate hypotheses, but cannot establish a clean paired infill
effect or select a final method.

## 3. First subsequent research milestone

Read and identify the exact grid-bootstrap version and reproduce its published
regular-sampling experiment before introducing an adaptation. Record the null
statistic, nuisance estimates, treatment of the observed initial state, bootstrap
sample count, quantile rule and candidate grid. Record code provenance and license
if author code is used. No such baseline is declared implemented by this protocol.

Then implement full set inversion that allows \([0,U]\), \([L,U]\),
\([0,\infty)\), disconnected sets and numerical nonresolution. Record boundary
inclusion, every located crossing, cap contact, tail diagnostics and unresolved
regions. A set reaching the search boundary has no certified finite upper
endpoint. A finite grid is not a certification of all continuum crossings.
Use the analytic high-reversion limit as a diagnostic and preserve ambiguity
when the threshold cannot be separated from it numerically.

## 4. Separate designs for density, span and schedule

| Question | Fixed quantities | Varied quantity | Path coupling |
|---|---|---|---|
| Fixed-span infill | Physical \(T,a,\kappa,\sigma,X_0\) | Mesh and \(n\) | Simulate exactly on a common fine grid; derive coarser samples by subsampling |
| Longer span | Physical parameters, \(X_0\), observation step | \(T\), hence \(n\) | Use prefixes of a common longest exact trajectory |
| Sampling schedule | Physical parameters, \(T,n,X_0\) | Predeclared regular/irregular schedule | For deterministic schedules use a union grid when paired comparisons are desired |
| Nuisance sensitivity | Declared dimensionless \(c=\kappa T\) and schedule | \(\delta=(a-\kappa X_0)\sqrt T/\sigma\), or separately specified starts | Explicitly identify each altered model component |

Independent random schedules require a specified schedule distribution and
conditioning convention. Endogenous times, measurement error and non-Gaussian
innovations are separate misspecification experiments; ordinary OU likelihood
validity does not automatically extend to them. Known-nuisance oracle comparisons
diagnose mechanisms and are not deployable competitors in the unknown-nuisance
problem.

## 5. Outcomes and uncertainty

The independent trajectory is the Monte Carlo unit. Predeclare pointwise coverage
over the nuisance grid, zero-exclusion probability, finite/unbounded/disconnected
set frequencies, unresolved-tail frequency, component widths, half-life geometry,
fit failures, cap events and runtime. Estimate paired method/design differences
on genuinely common paths. Do not treat observations within a trajectory as
independent Monte Carlo replications.

Every attempted trajectory stays in the reported denominator. If a metric is
undefined after failure, report its missing count and conservative aggregate
bounds: for \(S\) observed successes, \(F\) unresolved trajectories and \(N\)
attempts, the success fraction lies in \([S/N,(S+F)/N]\). Report failure
fractions separately. A prespecified conservative fallback can be analyzed as
part of a procedure, but cannot be invented after seeing failures.

For a binary rate with complete outcomes, report a binomial interval as well as
\(\sqrt{\widehat p(1-\widehat p)/N}\). Zero standard error at an empirical
rate of zero or one is not proof of zero risk. Widths conditional on finite sets
must be labeled conditional; retain the unbounded fraction and do not call a
finite-only average unconditional width. Map half-life sets componentwise and
preserve infinity whenever zero belongs to the mean-reversion set.

## 6. Confirmation gate

Before any confirmation run, freeze the method, source revision, configurations,
candidate and nuisance grids, random seed family, path coupling, stopping rule,
failure treatment, metrics and comparison hypotheses. Choose trajectory and
bootstrap counts from desired Monte Carlo precision, including bootstrap
quantile error, rather than convenience alone. Development seed families remain
excluded. Any change motivated by confirmation output returns the changed
analysis to development and requires fresh locked confirmation evidence.

Current confirmation status: not run. No parameter tuning, large confirmatory
study, new statistical method or completed grid-bootstrap reproduction follows
from the migration milestone.
