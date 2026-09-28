# System 1 — Perturbation (policy pipeline)

## A. Starter: the futile-retry test

Captured in `perturb_retry_tests.txt` (`14 passed in 4.26s`).

The test asserting that a null required field escalates with exactly one API call is
`test_ac_01_04_missing_source_halts_immediately` (`tests/test_us01_retry.py`, line 329).
Docstring: `"""Null required field => RetryFutileEscalation, exactly one API call."""`

Assertion lines (tests/test_us01_retry.py:357-360):

```python
assert isinstance(result, RetryFutileEscalation)
assert result.field == "endorsements"
assert result.detected_pattern == "endorsements_absent"
assert client.call_count == 1  # no further API call
```

Result line: `tests/test_us01_retry.py::test_ac_01_04_missing_source_halts_immediately PASSED`

## B. Own experiment 1 (offline): aggregate calibration hides a failing cell

- **Change:** `calib_perturbed.py` = `calib.py` plus 20 more correct auto/premium_amount labels at confidence 0.95.
- **Command:** `C:\ev\policy\Scripts\python.exe calib_perturbed.py`
- **Prediction:** OVERALL Brier drops; umbrella/exclusions stays at acc=0.00.

| Cell / metric | `calibration.txt` | `calibration_perturbed.txt` |
|---|---|---|
| auto premium_amount | `n=3 conf=0.95 acc=1.00 brier=0.003` | `n=23 conf=0.95 acc=1.00 brier=0.003` |
| umbrella exclusions | `n=2 conf=0.93 acc=0.00 brier=0.865` | `n=2 conf=0.93 acc=0.00 brier=0.865` |
| overall | `OVERALL brier=0.291` | `OVERALL brier=0.069` |

- **Outcome:** as predicted. The overall Brier improved from 0.291 to 0.069 by adding easy, correct samples, while the umbrella/exclusions cell did not change at all.

## C. Own experiment 2 (live API): a required field is actually missing

- **Change:** copied `data/policies/POL-2025-001.txt` to a temp folder and blanked the value on the
  `Total Policy Premium` line (the copy is saved as `perturbed_input/POL-2025-001_premium_blanked.txt`; the original is untouched).
- **Command:** `policy-extractor extract <temp>\POL-2025-001.txt --policy-id POL-2025-001`
- **Prediction:** one API call, then a `missing_source` escalation and no invented premium.
- **Actual (`perturb_blank_field.txt`):**
  - exactly one `POST https://claude.vocareum.com/v1/messages "HTTP/1.1 200 OK"` line
  - `"category": "missing_source"`
  - `"detected_pattern": "premium_amount_absent"`
  - `"kind": "escalation"`
  - reason: `Retry is futile; escalate to human review.`
- **Baseline, unperturbed (`baseline_extract.txt`):** `"premium_amount": 1847.62`, `"retry_count": 0`, `"kind": "extraction"`.
- **Difference:** the only change to the input turned a clean extraction into an immediate escalation after one call. No premium value was made up.
