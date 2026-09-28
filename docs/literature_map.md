# Literature map and access status

Search and targeted refresh: 2026-09-28 UTC. Primary sources below establish substantial prior art. This is not a completed systematic novelty review. Access limitations do not establish a research gap, and retrieving a manuscript does not establish an algorithm reproduction. No third-party manuscript or author code is redistributed here.

## Core references

### 1. Tang and Chen (2009)

Cheng Yong Tang and Song Xi Chen, *Parameter estimation and bias correction for diffusion processes*, Journal of Econometrics 149(1), 65-81.
DOI: 10.1016/j.jeconom.2008.11.001.
Publisher: https://www.sciencedirect.com/science/article/pii/S030440760800208X
Author PDF: https://www.songxichen.com/Uploads/Files/Publication/Tang-Chen-09-JoE.pdf

Relevance: different finite-sample behavior of drift and diffusion estimation; bootstrap bias correction and analytical results. Existing bias correction is not our contribution. Read its assumptions, OU parameterization, nuisance treatment and initialization before implementing a named baseline.
Access: the earlier review recorded retrieval of a 17-page author PDF followed by timeouts. The migration refresh again timed out at the author PDF; the publisher request failed. Bibliographic identity is independently supported by the author's [institutional publication list](https://en.mis.sdu.edu.cn/People/Visiting_Professors/Professor/Songxi_CHEN/Selected_Publications.htm). No full-text theorem or algorithm audit was completed in this refresh. The earlier abstract-level assessment is retained with that limitation.

### 2. Yu (2012)

Jun Yu, *Bias in the estimation of the mean reversion parameter in continuous time models*, Journal of Econometrics 169(1), 114-122.
DOI: 10.1016/j.jeconom.2012.01.004.
https://www.sciencedirect.com/science/article/abs/pii/S030440761200005X

Relevance: bias approximations in near-unit-root/slow-reversion settings, including a known-long-run-mean setting. Do not transfer a known-mean result directly to our unrestricted unknown-intercept boundary family. The density-versus-span distinction is established.
Access: the migration refresh verified the [SMU institutional record](https://ink.library.smu.edu.sg/soe_research/1348/), which identifies an accepted version and confirms the known-long-run-mean scope. Its download request and the publisher request failed. The prior publisher fetch had returned 403. Full formulas and proofs remain unverified. The institutional record lists CC BY-NC-ND 4.0 for that manuscript; this is not a license to redistribute adapted author code.

### 3. Hansen (1999)

Bruce E. Hansen, *The Grid Bootstrap and the Autoregressive Model*, Review of Economics and Statistics 81(4), 594-607.
https://direct.mit.edu/rest/article/81/4/594/57169/The-Grid-Bootstrap-and-the-Autoregressive-Model

Relevance: a strong grid-inversion bootstrap baseline, not the same as a naive percentile bootstrap at the unconstrained estimate. Record the exact algorithm and inversion statistic rather than vaguely naming any bootstrap after this paper.
Access: the migration refresh located the [author-hosted journal PDF](https://users.ssc.wisc.edu/~behansen/papers/restat_99.pdf). Section II and equation (5) distinguish candidate-specific bootstrap quantiles from quantiles evaluated only at the unrestricted estimate. The [author's program page](https://users.ssc.wisc.edu/~behansen/progs/restat_99.html) offers Gauss, Matlab and R files. Those programs were not downloaded, licensed or reproduced. The article's author page states copyright restrictions; do not infer an open-source code license from availability.

### 4. Lui, Xiao and Yu (2022)

Yiu Lim Lui, Weilin Xiao and Jun Yu, *The Grid Bootstrap for Continuous Time Models*, Journal of Business & Economic Statistics 40(3), 1390-1402.
DOI: 10.1080/07350015.2021.1930014.
Author repository: https://ink.library.smu.edu.sg/soe_research/2636/
Publisher: https://doi.org/10.1080/07350015.2021.1930014
Earlier working record: https://ink.library.smu.edu.sg/soe_research/2210/

Relevance: expressly addresses initial conditions, infill asymptotics and uniform inference for persistence. Therefore an OU project cannot claim that taking initial conditions or high-frequency finite-span inference seriously is itself novel. Compare its assumptions with our fixed-X0, unknown-a/unknown-sigma, irregular-time experiment. Its asymptotic guarantee must not be called exact finite-sample validity.
Access: the migration refresh verified journal metadata and abstract, including the final article's emphasis on modified initialization. The SMU submitted-version download failed again. A [DUFE-hosted working manuscript dated July 1, 2020](https://iaer.dufe.edu.cn/file/b5733822-ae58-11ec-beb7-005056a49984/3.pdf) was retrieved: 40 pages, with the introduction and Sections 2–3 inspected. It uses equally spaced observations and the drift form \(\kappa(\mu-X_t)\). Subsequent section-level retrieval failed. This manuscript predates the 2022 journal version and must not be substituted silently for its final algorithm or theorem statements. Full version comparison, proofs, author-code revision/license and algorithm reproduction remain open.

### 5. Wasserman, Ramdas and Balakrishnan (2020)

Larry Wasserman, Aaditya Ramdas and Sivaraman Balakrishnan, *Universal inference*, PNAS 117(29), 16880-16890.
DOI: 10.1073/pnas.1922664117.
https://arxiv.org/abs/1912.11436
https://arxiv.org/pdf/1912.11436
https://www.pnas.org/doi/10.1073/pnas.1922664117

Version inspected again: [arXiv v4](https://arxiv.org/pdf/1912.11436v4), submitted 2022-10-19, whose PDF title page is dated October 21, 2022; 28 pages. These dates are distinct from the 2020 publication year. Section 6, equations (13)–(14), treats nuisance profiling; the same section discusses upper bounds on the null maximum and conditional likelihoods for non-iid observations. The PMC text was initially accessible but a later request encountered a browser check; the arXiv PDF remained accessible. This establishes the antecedent for the conditional split construction; it does not certify our numerical implementation.

The present work supplies an explicit scalar-OU specialization and numerical audit, without a new general e-value theorem.

### 6. Phillips and Yu: persistent diffusion estimation

Peter C. B. Phillips and Jun Yu, *Jackknifing Bond Option Prices*, Review of Financial Studies 18(2), 707–742 (2005), DOI: 10.1093/rfs/hhi018.

The [Cowles Foundation Discussion Paper 1392](https://cowles.yale.edu/sites/default/files/2022-08/d1392.pdf) was retrieved in the migration refresh. Its cover is dated January 2003 and it has 52 PDF pages. It is a working version, not the 2005 journal text. Much extracted text has an unusable font encoding, so only readable introductory material and the cover were used. It documents established concern with diffusion parameter bias and jackknife correction; it supplies no inference guarantee adopted by this repository. A detailed proof audit and comparison with the journal version remain open.

## Overlap and unresolved differences

| Proposed topic | Existing overlap | What remains to establish here |
|---|---|---|
| Exact OU likelihood and drift bias | Gaussian transition theory; Tang–Chen and Yu literature | Numerical fidelity, boundary handling and transparent nuisance profiling; no novelty claim |
| Persistence-aware bootstrap | Hansen Section II, equation (5); Lui–Xiao–Yu continuous-time work | Faithful final-version reproduction, initialization, and any necessary irregular-time/unrestricted-drift adaptation |
| Split/profile finite-sample coverage | Universal Inference Section 6, equations (13)–(14), conditional-likelihood discussion | Model-specific implementation accuracy; no new validity principle |
| Density versus span and initial conditions | Lui–Xiao–Yu working-version Sections 2–3 and final abstract | A controlled paired design and a substantive efficiency question beyond these established distinctions |
| Fixed-span informativeness with nuisance profiling | Overlap not exhaustively mapped | An OU-specific analytical or consequential empirical result; currently a research question |

In particular, the working grid-bootstrap model writes drift as \(\kappa\mu\), whereas this project's boundary retains arbitrary \(a\). Whether the final algorithm and assumptions cover the unrestricted Brownian-with-drift boundary must be checked explicitly. This observation identifies a comparison requirement, not a proven literature gap.

## Recent adjacent leads: not audited and not evidence of a gap

- *Estimation bias in the Ornstein-Uhlenbeck process with flow data*, 2025, DOI 10.1080/07474938.2025.2515518. Publisher-indexed content was encountered; authors/version/full assumptions need verification. Flow/aggregated observations differ from our point observations. Do not borrow its likelihood unmodified.
  https://www.tandfonline.com/doi/full/10.1080/07474938.2025.2515518
- Park, Balakrishnan and Wasserman, *Robust universal inference*, Biometrika 113(2), asaf070 (2026 volume; online 2025). Separate misspecification methods; our ordinary exact-OU likelihood guarantee does not inherit robustness.
  https://academic.oup.com/biomet/article/113/2/asaf070/8321921
  https://arxiv.org/abs/2307.04034

## Required next search

Read full core papers; then search primary literature for OU/persistent-AR confidence sets with unknown intercept, boundary kappa=0, deterministic irregular sampling, exact tests, conditional likelihood e-values in Markov models, and universal-inference efficiency under fixed-domain/infill asymptotics. Record date, exact version, section/theorem, parameter restrictions, observation scheme and implementation revision/license.

Add an overlap table: claimed question -> exact earlier result -> genuine difference or no difference. An unsuccessful search is NOT evidence of originality. Do not publish instructor materials or copyrighted paper copies as part of a public repository.
