# Exact OU likelihood and finite-horizon inference

These derivations justify the mathematical core, not a claim of a new method.
The transition law and Gaussian profiling are elementary specializations of
established theory. The split construction specializes universal inference.
Numerical checks and the scope of the implemented procedures are described in
[methodology.md](methodology.md); empirical evidence belongs in
[findings.md](findings.md).

## 1. Experiment and notation

Observe one trajectory at fixed times
\(0=t_0<t_1<\cdots<t_n=T<\infty\), conditional on fixed \(X_0=x_0\), under

\[
dX_t=(a-\kappa X_t)\,dt+\sigma\,dW_t,
\qquad a\in\mathbb R,\quad\kappa\geq0,\quad\sigma>0.
\]

The same formulas apply conditionally on an independently randomized schedule.
Here “exogenous” means that conditioning on the schedule leaves these transition
laws unchanged. Endogenous times, observation noise and aggregated observations
are different experiments. No stationary initial density is included.
The long-run mean \(a/\kappa\) is defined only for \(\kappa>0\). Restricting it
to a bounded set would remove Brownian motions with nonzero drift from the
boundary family considered here.

## 2. Exact transitions and the Brownian boundary

For a gap \(\Delta>0\), variation of constants gives

\[
X_{t+\Delta}=\phi X_t+ab+
\sigma\int_t^{t+\Delta}e^{-\kappa(t+\Delta-s)}\,dW_s,
\]

where

\[
\phi=e^{-\kappa\Delta},\qquad
b=\int_0^\Delta e^{-\kappa u}\,du,
\qquad v=\int_0^\Delta e^{-2\kappa u}\,du.
\]

Independent Brownian increments and the Itô isometry yield
\(X_{t+\Delta}\mid X_t\sim N(\phi X_t+ab,\sigma^2v)\).
For positive \(\kappa\),
\(b=-\operatorname{expm1}(-\kappa\Delta)/\kappa\) and
\(v=-\operatorname{expm1}(-2\kappa\Delta)/(2\kappa)\).
At zero the exact values are \((\phi,b,v)=(1,\Delta,\Delta)\).
In particular \(v>0\), with no positive lower bound on \(\kappa\).

For two adjacent gaps the identities
\(\phi_{12}=\phi_2\phi_1\),
\(b_{12}=\phi_2b_1+b_2\), and
\(v_{12}=\phi_2^2v_1+v_2\) follow by splitting the integrals.
They justify exact simulation on a fine grid followed by subsampling.
Using the same standard normal draws at two different meshes does not produce
this nested-path coupling.

## 3. Conditional likelihood and full nuisance supremum

Write \(r_i(\kappa)=x_i-\phi_i x_{i-1}\). The log likelihood is

\[
\ell(\kappa,a,s^2)
=-\frac12\sum_{i=1}^n
\left[\log(2\pi s^2v_i)+\frac{(r_i-ab_i)^2}{s^2v_i}\right],
\qquad s^2=\sigma^2>0.
\]

For every finite candidate \(\kappa\), \(A=\sum_i b_i^2/v_i>0\). Completing
the square gives

\[
\widehat a_\kappa=\frac{\sum_i b_ir_i/v_i}{A},\qquad
\sum_i\frac{(r_i-ab_i)^2}{v_i}
=R_\kappa+A(a-\widehat a_\kappa)^2,
\]

where \(R_\kappa=\sum_i(r_i-\widehat a_\kappa b_i)^2/v_i\).
If \(R_\kappa>0\), maximizing over \(s^2\) gives the unique nuisance maximizers
and profile

\[
\widehat\sigma^2_\kappa=R_\kappa/n,\qquad
\ell_p(\kappa)=-\frac12
\left[n\{\log(2\pi\widehat\sigma^2_\kappa)+1\}
+\sum_i\log v_i\right].
\]

The divisor is \(n\), the number of transitions, not a residual degrees-of-freedom
divisor. If \(R_\kappa=0\), the likelihood diverges as \(s^2\downarrow0\): its
supremum is \(+\infty\) on the log scale, without an admissible variance MLE.
This must remain a flagged degeneracy. Replacing zero by a variance floor changes
the supremum and can invalidate the denominator of a likelihood e-value.

At \(\kappa=0\), these expressions reduce exactly to the irregularly sampled
Brownian-with-drift likelihood. For equal gaps and \(\kappa>0\), writing
\(\alpha=ab\) recovers a Gaussian AR(1) regression conditional on \(x_0\),
with slope \(\phi\in(0,1)\). Unconstrained OLS slopes outside this range cannot
be silently transformed to an admissible OU estimate.

## 4. The high-reversion profile limit

This is a statement about the profiled likelihood for a fixed finite observation
vector and fixed positive gaps. It does not add \(\kappa=\infty\) to the model.
For \(\kappa>0\), reparameterize the unrestricted nuisance parameters by
\(\beta=a/\kappa\) and \(\tau^2=\sigma^2/(2\kappa)\). Then

\[
\mu_i=\phi_i x_{i-1}+\beta(1-\phi_i),\qquad
\operatorname{Var}(X_i\mid X_{i-1})=\tau^2w_i,
\quad w_i=1-\phi_i^2.
\]

As \(\kappa\to\infty\), all \(\phi_i\to0\), \(w_i\to1\), and the explicit
weighted least-squares formulas give
\(\widehat\beta_\kappa\to\bar x_+\) and
\(\widehat\tau^2_\kappa\to s_+^2\), where
\(\bar x_+=n^{-1}\sum_{i=1}^n x_i\) and
\(s_+^2=n^{-1}\sum_{i=1}^n(x_i-\bar x_+)^2\).
For \(s_+^2>0\), continuity of this explicit profile proves

\[
\lim_{\kappa\to\infty}\ell_p(\kappa)
=-\frac n2\{\log(2\pi s_+^2)+1\}.
\]

If \(x_1=\cdots=x_n=q\), choose \(\beta=q\). The transformed residuals tend
to zero and \(w_i\to1\); hence the profiled transformed residual variance tends
to zero and \(\ell_p(\kappa)\to+\infty\). This includes the case \(x_0\ne q\),
where the profile need not be degenerate at any finite candidate. If all
observations including \(x_0\) equal \(q\), choosing \(a=\kappa q\) gives
zero residuals already at each finite candidate. These are extended-real limits.

A bounded search can miss a better finite mode or the tail. Comparing its best
value with the analytic limit is a useful diagnostic, not a global-optimality
certificate. A limit equal to a confidence-set threshold does not decide tail
membership; even a strict limit inequality provides no numerical cutoff without
a bound on the approach to the limit.

## 5. Equivariance and dimensionless parameters

For a time-unit change \(t'=\lambda t\), \(\lambda>0\), the equivalent
parameters are \((\kappa/\lambda,a/\lambda,\sigma/\sqrt\lambda)\). Conditional
means, variances and the likelihood are unchanged. For \(Y=sX+d\), \(s\ne0\),
the equivalent parameters are \((\kappa,sa+\kappa d,|s|\sigma)\), and the
log likelihood changes by \(-n\log|s|\). Profile likelihood ratios are invariant.

For \(U_s=(X_{Ts}-x_0)/(\sigma\sqrt T)\), Brownian scaling gives

\[
dU_s=(\delta-cU_s)\,ds+dB_s,
\quad c=\kappa T,\qquad
\delta=(a-\kappa x_0)\sqrt T/\sigma.
\]

The normalized schedule \((t_i/T)\) matters as well. Thus \(c\) alone does not
describe every drift, initialization and sampling experiment.

## 6. Restricted continuous-path information bound

In this section only, \(a=0\), \(x_0=0\), and the same known \(\sigma>0\)
is used under both laws. Let \(P_\kappa\) and \(P_0\) be laws on continuous
paths over \([0,T]\), with mean reversion \(\kappa\) and zero, respectively.

Under \(P_0\), \(X_t=\sigma W_t\). The candidate likelihood-ratio process is

\[
L_t=\exp\left\{-\frac\kappa\sigma\int_0^tX_s\,dW_s
-\frac{\kappa^2}{2\sigma^2}\int_0^tX_s^2\,ds\right\}
=\exp\left\{\frac{\kappa t}{2}
-\frac{\kappa X_t^2}{2\sigma^2}
-\frac{\kappa^2}{2\sigma^2}\int_0^tX_s^2\,ds\right\}.
\]

The second equality is Itô's formula. For \(\kappa\geq0\) and \(t\leq T\),
\(0<L_t\leq e^{\kappa T/2}\). Localize the stochastic exponential; its stopped
versions obey the same bound. Dominated convergence makes the positive local
martingale a true martingale with \(E_0L_t=1\). Thus no unverified Novikov
condition for arbitrary \(T\) is needed here. Girsanov's theorem identifies
\(L_T=dP_\kappa/dP_0\), since the resulting linear SDE has a unique law.

Under \(P_\kappa\),
\(\operatorname{Var}_\kappa X_t=\sigma^2(1-e^{-2\kappa t})/(2\kappa)\).
The stochastic integral in the log ratio expressed under this law has expectation
zero: its second moment is finite over the finite horizon. Consequently,

\[
D(P_\kappa\Vert P_0)
=\frac{\kappa^2}{2\sigma^2}\int_0^T E_\kappa X_t^2\,dt
=\frac c4-\frac{1-e^{-2c}}8
=\frac{c^2}4-\frac{c^3}6+O(c^4),\quad c=\kappa T.
\]

The expression is zero at \(c=0\). A Taylor series near zero avoids cancellation
when evaluating the formula; that numerical approximation is separate from the
exact identity.

## 7. Sampled information and testing power

The chain rule for KL and the univariate normal KL formula give, for the same
restricted pair of laws and deterministic schedule,

\[
D(P_\kappa^{\mathrm{sample}}\Vert P_0^{\mathrm{sample}})
=\frac12\sum_{i=1}^n\left[
\frac{v_i}{\Delta_i}-1-\log\frac{v_i}{\Delta_i}
+\frac{(\phi_i-1)^2V_{i-1}}{\Delta_i}\right],
\quad
V_{i-1}=\frac{\operatorname{Var}_\kappa X_{t_{i-1}}}{\sigma^2}.
\]

The conditional Brownian mean is \(X_{i-1}\); the squared conditional mean
difference under OU is \((\phi_i-1)^2X_{i-1}^2\). Taking its OU expectation
produces the last term. At zero the entire expression is zero.

For stable evaluation, with \(z=\kappa\Delta\), form
\(u=v/\Delta-1=-z+2z^2/3-z^3/3+O(z^4)\) directly when \(z\) is small, then
use \(u-\log(1+u)=u^2/2-u^3/3+O(u^4)\). Computing \(v/\Delta\) first can
round it to one and lose a representable KL term. For a fixed finite schedule,
the leading sampled KL is
\(\kappa^2\{\sum_i\Delta_i^2+2\sum_i\Delta_i t_{i-1}\}/4
=\kappa^2T^2/4\), since the sum telescopes to \(T^2\). This supplies an
independent small-reversion check even for a single terminal observation.

Sampling is a measurable map on path space, so data processing implies sampled
KL is no larger than continuous-path KL. For nested grids, a coarser sample is a
map of the finer one, proving monotonicity under refinement. Numerical convergence
to the path formula is a useful check; the code does not establish a general
convergence-rate theorem for arbitrary meshes.

If \(0\leq\psi\leq1\) is any possibly randomized test with
\(E_0\psi\leq\alpha\), total variation and Pinsker give

\[
E_\kappa\psi\leq
\min\{1,\alpha+\sqrt{D(P_\kappa\Vert P_0)/2}\}.
\]

For a sampled test one may instead use the smaller sampled KL. This is a pairwise
upper bound in the restricted experiment, not a sharp minimax bound, an attained
power curve, or a full analysis of unknown drift and scale. A test uniformly
valid for the composite Brownian-with-drift null must in particular satisfy the
size condition at this restricted null, but that does not extend this formula
unchanged to every alternative drift or initial state.

## 8. Chronological split profile e-value

Choose a fixed split \(m\). Fit a positive-variance conditional density using
only \(\mathcal F_m=\sigma(X_0,\ldots,X_m)\) and the exogenous schedule. For
each realized prefix, let \(q(\cdot\mid\mathcal F_m)\) be a measurable density
on \((X_{m+1},\ldots,X_n)\) integrating to one. A fitted exact OU transition
product has this property even when its training optimization is approximate.
Define

\[
E_\kappa=\frac{q(X_{m+1:n}\mid\mathcal F_m)}
{\sup_{a\in\mathbb R,\sigma>0}
p_{\kappa,a,\sigma}(X_{m+1:n}\mid X_m)}.
\]

An infinite denominator gives \(E_\kappa=0\) for a finite numerator. At the true
\((\kappa_0,a_0,\sigma_0)\), denominator domination and conditional integration
give

\[
E_{\kappa_0,a_0,\sigma_0}[E_{\kappa_0}\mid\mathcal F_m]
\leq\int q(y\mid\mathcal F_m)\,dy=1.
\]

The conditioning accounts for the shared boundary state \(X_m\); no
prefix/suffix independence is assumed. Markov's inequality therefore proves
\(P(\kappa_0\in C_\alpha)\geq1-\alpha\) for
\(C_\alpha=\{\kappa\geq0:E_\kappa\leq1/\alpha\}\).
This is the conditional-density specialization of
[universal inference](https://arxiv.org/pdf/1912.11436v4), Section 6, equations
(13)–(14), and its discussion of conditional likelihoods for non-iid data.

Future-informed parameter fitting need not define such a normalized conditional
density. A smaller, locally optimized denominator is also insufficient; the full
supremum or a certified upper bound is required. Floating-point evaluation of an
analytic supremum is not an interval-arithmetic certificate. A failed training
fit must remain a failure unless a normalized fallback was specified in advance.

The result is fixed-horizon and model-based, with no automatic confidence-sequence,
optional-stopping, prediction-interval or misspecification-robust interpretation.
Deterministic convex combinations of valid split e-values retain expectation at
most one; selecting the largest after inspecting results generally does not.
Neither variant is introduced here as a new method.

## 9. Confidence-set and half-life geometry

No connectedness or finite upper endpoint has been proved for these inversion
sets. Full inversion must allow boundary inclusion, disconnected components,
unbounded components and unresolved numerical regions. Membership on a finite
grid certifies only the reported grid evaluations, not continuum endpoints.

For any set \(C\subseteq[0,\infty)\), its half-life image is

\[
H(C)=\{\log(2)/\kappa:\kappa\in C,\ \kappa>0\}
\ \cup\ \{+\infty:0\in C\}.
\]

For \(0<L\leq U<\infty\), \([L,U]\) maps to
\([\log(2)/U,\log(2)/L]\). The set \([0,U]\) maps to
\([\log(2)/U,+\infty]\) in the extended-real space.
An unbounded positive \(\kappa\) component approaches half-life zero but never
contains zero, because infinite \(\kappa\) is not a model point. Apply this map
componentwise; preserve open endpoints and numerical nonresolution.

## 10. Status of the claims

| Claim | Status in this repository |
|---|---|
| Exact transition, Gaussian profile, equivariance and iid profile limit | Elementary derivations above; no originality claim |
| Restricted path/sample KL, change of measure and Pinsker implication | Derived above from standard tools; no novelty claim |
| Fixed-horizon conditional split coverage | Established universal-inference principle specialized above |
| Accuracy of finite-precision formulas on tested cases | Numerical validation only |
| Global profile maximum, certified continuum endpoints or all tail crossings | Unresolved |
| Finite-sample exactness of plug-in bootstrap | Not established and not claimed |
| New method, OU-specific efficiency theorem, uniform empirical coverage | Not established |
