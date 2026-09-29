# Evidence Pack — Summary

Run date 2026-09-28 · Windows 11 · Python 3.11.9 · **Live API used** (Vocareum proxy) for System 1 and the System 2 perturbation. Details in `NOTES.md`.

| System | Tests | mypy | ruff | Key run outcome | Perturbation |
|---|---|---|---|---|---|
| 1. Policy pipeline | `45 passed, 3 skipped` (re-run 2026-09-29; the 3 `live` tests skip without an API key). The earlier live-key run hit a proxy HTTP 400 on 2 live tests (`tests_live_proxy_400_earlier.txt`). `routing_offline.txt`: `9 passed` | `Success: no issues found in 11 source files` | `All checks passed!` | Live pipeline: 0 auto_approve / 9 human_review / 0 spot_check, 1 escalation (POL-2025-009 `endorsements_absent`). Calibration: umbrella exclusions `conf=0.93 acc=0.00`, `OVERALL brier=0.291` | Blanked premium → `missing_source` / `premium_amount_absent` after 1 API call (baseline `1847.62`). 20 extra easy labels → `OVERALL brier=0.069`, umbrella cell unchanged |
| 2. Mortgage extraction | `25 passed` (validator subset: `8 passed`) | `Success: no issues found in 11 source files` | `All checks passed!` | sqft `2400` (int); missing bonus `null`; sum mismatch flagged `"delta": -1250.0`, exit 1 | Stated total made to match (live record) → `"consistent": true`, `"discrepancies": []`, exit 0 |
| 3. Supply chain | `34 passed, 2 warnings` | `Success: no issues found in 8 source files` | `All checks passed!` | 3 sections present; on-time conflict 95.0% (supplier_audit, 2026-04-10) vs 78.0% (logistics, 2026-04-05) under Contested | `--simulate-timeout`: run completes, logistics marked unavailable, `late_shipment_count` → Incomplete. **On-time conflict disappears** (moves to Well-Established, single source, 95%) |

## Artifacts

**Root (`evidence/`)**
- `SUMMARY.md` — this file
- `environment.txt` — Python, OS and tool versions
- `NOTES.md` — environment, API path, problems and fixes
- `reflection-brief.md` — completed course brief (fill in Name)
- `perturbation-log.md` — completed course perturbation log
- `install-policy.txt`, `install-mortgage.txt`, `install-supply.txt` — successful `pip install -e ".[dev]"` logs
- `install-policy-FAILED-longpath-earlier-attempt.txt` — earlier failed install (Windows MAX_PATH), kept as evidence for NOTES §1

**`01-policy-pipeline/`**
- `tests.txt`, `tests_live_proxy_400_earlier.txt`, `tests_live_rerun.txt`, `routing_offline.txt`, `perturb_retry_tests.txt`
- `mypy.txt`, `ruff.txt`, `static-checks.txt`
- `pipeline_run.txt`, `routing_decisions.json`
- `calib.py`, `calibration.txt`, `calib_perturbed.py`, `calibration_perturbed.txt`
- `baseline_extract.txt`, `perturb_blank_field.txt`, `perturbed_input/POL-2025-001_premium_blanked.txt`
- `perturbation.md`, `reflection.md`

**`02-mortgage-extraction/`**
- `tests.txt`, `validator_tests.txt`
- `mypy.txt`, `ruff.txt`, `static-checks.txt`
- `run_appraisal_sqft.txt`, `run_missing_bonus.txt`, `run_sum_mismatch.txt`
- `run_sum_matched_live.txt`, `perturbed_input/income_sum_matched.txt`
- `perturbation.md`, `reflection.md`

**`03-supply-chain/`**
- `tests.txt`
- `mypy.txt`, `ruff.txt`, `static-checks.txt`
- `briefing_normal.txt`, `briefing_timeout.txt`, `briefing_diff.txt`
- `perturbation.md`, `reflection.md`

**Screenshots** (offline/replay re-runs; each shows the command line)
- `01-policy-pipeline/screenshots/policy-tests.png` — `pytest tests/ -m "not live" -q` → 45 passed, 3 deselected (the 3 live tests excluded; matches the runbook's expected 45)
- `01-policy-pipeline/screenshots/policy-calibration.png` — `python calib.py` → umbrella exclusions acc=0.00, OVERALL brier=0.291
- `02-mortgage-extraction/screenshots/mortgage-tests.png` — `pytest tests/ -q` → 25 passed
- `02-mortgage-extraction/screenshots/mortgage-discrepancy.png` — `mortgage-extract income_sum_mismatch.txt --mode replay` → consistent false, delta -1250.0
- `03-supply-chain/screenshots/supply-normal-contested.png` — `supply-chain-investigate meridian --offline` → Contested 95.0% vs 78.0%
- `03-supply-chain/screenshots/supply-timeout.png` — `... --simulate-timeout` → "Sources unavailable: logistics unavailable (timeout)", Contested _none_, late_shipment_count in Incomplete
