"""Regenerate deterministic validation data from the frozen Python reference.

This script is validation infrastructure, not a second research implementation.
It writes only to a new output directory and never modifies the frozen source.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import importlib.metadata
import json
from pathlib import Path
import platform
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
FROZEN = ROOT / "reference/python_v1"
EXPECTED_CORE_SHA256 = "2c728d16c26d94ecf3e4b9308d41e51adab973a607b9f78c8413b9ea51bd6a61"
core = FROZEN / "src/ouinfer/core.py"
if not core.exists() or hashlib.sha256(core.read_bytes()).hexdigest() != EXPECTED_CORE_SHA256:
    raise SystemExit("Frozen Python core unavailable or changed; no fixtures generated.")
sys.path.insert(0, str(FROZEN / "src"))
from ouinfer.core import (coefficients, fit_profile, kl_continuous, kl_discrete,
                         loglik, profile, simulate, split_log_e, split_numerator)


def write_rows(path, rows):
    with path.open("x", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=False)
    # Decimal inputs are fixed design choices, not fitted to observed discrepancies.
    innovations = np.array([.2, -1., .6, 1.3, -.7, .1, -.9, .4, .8, -.2,
                            -1.2, .7, .3, -.5, 1.1, -.4, .9, -.8, .5, -.3])
    kappas = [0., 1e-10, .1, 1., 7.]
    simulation_parameters = dict(kappa=.2, a=.3, sigma=.7, x0=-.4)
    data, transitions, profiles, fits, information = [], [], [], [], []
    for design in ["regular", "irregular"]:
        t = (np.linspace(0., 2., 21) if design == "regular"
             else np.r_[0., np.cumsum(np.linspace(.01, .19, 20))])
        x = simulate(t, **simulation_parameters, innovations=innovations)
        for i, (ti, xi) in enumerate(zip(t, x)):
            data.append(dict(design=design, index=i, t=float(ti), x=float(xi),
                             innovation=0. if i == 0 else float(innovations[i-1])))
        f = fit_profile(x, t)
        numerator, training = split_numerator(x, t, 10)
        fits.append(dict(design=design, kappa=f.profile.kappa, a=f.profile.a,
                         sigma2=f.profile.sigma2, loglik=f.profile.loglik, cap=f.cap,
                         hit_upper_cap=int(f.hit_upper_cap), tail_better=int(f.tail_better),
                         iid_limit_loglik=f.iid_limit_loglik, numerator=numerator,
                         training_kappa=training.profile.kappa, training_a=training.profile.a,
                         training_sigma2=training.profile.sigma2,
                         training_loglik=training.profile.loglik, split=10))
        for k in kappas:
            phi, b, v = coefficients(k, np.diff(t))
            for i in range(len(phi)):
                transitions.append(dict(design=design, kappa=k, index=i+1,
                                        phi=float(phi[i]), b=float(b[i]), v=float(v[i]),
                                        mean=float(phi[i]*x[i]+.3*b[i]),
                                        variance=float(.49*v[i])))
            p = profile(x, t, k)
            profiles.append(dict(design=design, kappa=k, a=p.a, sigma2=p.sigma2,
                                 loglik=p.loglik, given_loglik=loglik(x, t, k, .3, .49),
                                 lr=2*(f.profile.loglik-p.loglik),
                                 log_e=split_log_e(x, t, k, 10, numerator=numerator)))
            c = k*(t[-1]-t[0])
            kc = kl_continuous(c)
            information.append(dict(design=design, kappa=k, continuous=kc,
                                    discrete=kl_discrete(k, t),
                                    power=min(1., .05+np.sqrt(kc/2))))
    for name, rows in [("observations.csv", data), ("python_transition.csv", transitions),
                       ("python_profile.csv", profiles), ("python_fit.csv", fits),
                       ("python_information.csv", information)]:
        write_rows(args.out / name, rows)
    provenance = dict(
        purpose="Deterministic synthetic regression fixtures; no observed or coursework data",
        frozen_core_sha256=EXPECTED_CORE_SHA256,
        python_version=platform.python_version(),
        numpy_version=importlib.metadata.version("numpy"),
        scipy_version=importlib.metadata.version("scipy"),
        simulation_parameters=simulation_parameters,
        random_seed=None,
        innovation_policy="Explicit fixed innovations; cross-language RNG streams need not match",
        tolerances_fixed_before_comparison={
            "closed_form": {"atol": 1e-10, "rtol": 1e-10},
            "bounded_fit_objective_and_lr": {"atol": 1e-8, "rtol": 1e-8},
            "bounded_fit_parameters_and_predictive_score": {"atol": 2e-5, "rtol": 2e-5},
            "direct_nuisance_parameters": {"atol": 5e-6, "rtol": 5e-6},
            "direct_nuisance_objective": {"atol": 1e-9, "rtol": 1e-9}},
        sha256={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(args.out.glob("*.csv"))})
    (args.out / "python_provenance.json").write_text(json.dumps(provenance, indent=2)+"\n")
    print(f"Generated {sum(map(len, [data, transitions, profiles, fits, information]))} rows.")


if __name__ == "__main__":
    main()
