# System 2 — Reflection (schema-enforced two-pass mortgage extraction)

> Sentences marked **[opinion]** are judgment, not evidence. Edit them as you see fit.

## 1. What the system guarantees

Forced tool use gives output that always fits the schema. Nullable fields let the model say "the document didn't state this" rather than guess. Informal numbers are normalized at extraction time. A separate arithmetic validator reports a stated total that disagrees with its line items instead of silently correcting it.

## 2. Evidence

- `tests.txt`: `25 passed in 3.82s`. `static-checks.txt`: mypy `Success: no issues found in 11 source files`; ruff `All checks passed!`
- `run_appraisal_sqft.txt`: `"gross_living_area_sqft": 2400`, an integer normalized from "about 2,400 sq ft".
- `run_missing_bonus.txt`: `"bonus_monthly": null`. The missing bonus is returned as null, not invented.
- `run_sum_mismatch.txt`: `"calculated": 9642.17`, `"stated": 10892.17`, `"delta": -1250.0`, `"consistent": false`, `[exit code: 1]`.

## 3. What the perturbation showed

Making the stated total equal the line items (`run_sum_matched_live.txt`, live `--mode record`) gave `"consistent": true` and `"discrepancies": []`. So the flag is driven by the arithmetic alone. Valid JSON (schema guarantee) and a correct sum (validator guarantee) are separate properties: the mismatched document produced fully valid JSON and was still wrong.

## 4. Where it could still fail

- The validator checks one total only. In the perturbed copy the net-pay arithmetic is now wrong and nothing flagged it (`"discrepancies": []`).
- In the live run, `"bonus_ytd": null` was returned even though the document shows a YTD bonus of `3,500.00`. Null prevents fabrication but can also hide information the extractor missed. The schema can't tell "not stated" apart from "the extractor missed it". **[opinion]**
- A fixed $1.00 tolerance may be too loose for small components or too tight for large annualized figures. **[opinion]**
