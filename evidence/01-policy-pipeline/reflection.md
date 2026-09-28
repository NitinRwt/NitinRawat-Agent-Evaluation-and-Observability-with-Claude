# System 1 — Reflection (validated, routed policy pipeline)

> Sentences marked **[opinion]** are judgment, not evidence. Edit them as you see fit.

## 1. What the system guarantees

It won't auto-approve an extraction unless three independent signals all agree: per-field confidence, an independent reviewer model, and within-policy integration checks. It also stops retrying when the source document simply doesn't contain a field and escalates instead.

## 2. Evidence

- `tests.txt`: `2 failed, 46 passed in 13.96s`. Both failures are `live` tests that got `Model 'claude-haiku-4-5' is not available for your organization` from the Vocareum proxy. The same live test passed in `perturb_retry_tests.txt` (`test_live_extracts_well_formed_policy PASSED`), and `tests_live_rerun.txt` repeats the 400, so the proxy is intermittent. No offline test failed.
- `static-checks.txt`: mypy `Success: no issues found in 11 source files`; ruff `All checks passed!`
- `pipeline_run.txt` (live, `--seed 42`): `"auto_approve": 0`, `"human_review": 9`, `"spot_check": 0`, `"escalations": 1`.
- `routing_decisions.json`, POL-2025-002: every confidence ≥ 0.95, `"fields_below_threshold": []`, yet `"reason": "reviewer_disagreement=['coverage_limit', 'deductible']"`.
- `calibration.txt`: umbrella exclusions `conf=0.93 acc=0.00 brier=0.865`, `OVERALL brier=0.291`.

## 3. What the perturbation showed

- Blanking the premium (`perturb_blank_field.txt`) gave `"detected_pattern": "premium_amount_absent"` after one API call. The unperturbed baseline extracted `"premium_amount": 1847.62`.
- Adding 20 correct auto labels (`calibration_perturbed.txt`) moved the aggregate to `OVERALL brier=0.069`, while umbrella exclusions stayed at `acc=0.00 brier=0.865`.
- **Key insight:** the overall Brier score hides the badly calibrated umbrella/exclusions cell. A router that trusted aggregate confidence would auto-approve umbrella exclusions that were wrong 100% of the time in this sample (`acc=0.00`) at 0.93 confidence.

## 4. Where it could still fail

- Calibration is only as good as the labeled sample. The umbrella cell has `n=2`, which is too few to set a reliable threshold. **[opinion]**
- In this run every policy went to a human (`"human_review": 9`), mostly because of reviewer disagreement. If the reviewer disagrees this often in production, human review becomes the default path and reviewers may start rubber-stamping. **[opinion]**
- Missing-source detection depends on the model returning `null`. A model that guesses a plausible premium instead of `null` would get past this check. **[opinion]**
