# System 2 — Perturbation (mortgage extraction)

## A. Flagged vs clean (replay mode)

`run_sum_mismatch.txt`: the validator flags a discrepancy, and the CLI exits 1:

```
    "consistent": false,
        "field": "total_monthly_income",
        "calculated": 9642.17,
        "stated": 10892.17,
        "delta": -1250.0
[exit code: 1]
```

`run_appraisal_sqft.txt`: no flag, exit 0:

```
    "consistent": true,
    "discrepancies": []
[exit code: 0]
```

The exit code is part of the contract: `mortgage_extractor/__main__.py:74` is `return 0 if report.consistent else 1`.

## B. Own experiment 1: where the check lives and its rule

- **Location:** `mortgage_extractor/validator.py`, `validate()`. It compares
  `Income.calculated_monthly_total` (the sum of the component fields, computed in Python) with
  `Income.stated_monthly_total` (the total as printed in the document).
- **Rule:** `delta = round(calculated - stated, 2)` and a discrepancy is emitted when
  `abs(delta) > tolerance`. The default is `DEFAULT_TOLERANCE_USD = 1.00` (`config.py:10`), which absorbs cent-level OCR rounding.
  If either value is `None`, the check is skipped.
- **Unit tests:** `tests/test_us04_validator.py`, captured in `validator_tests.txt` (`8 passed in 2.61s`), including
  `test_ac_04_02_default_tolerance_is_one_dollar PASSED` and
  `test_ac_04_04_real_paystub_with_sum_mismatch_is_flagged PASSED`.

## C. Own experiment 2 (live API): make the stated total match

- **Change:** new fixture `fixtures/documents/income_sum_matched.txt` (copy saved in `perturbed_input/`), a copy of
  `income_sum_mismatch.txt` with the current stated total changed from `10,892.17` to `9,642.17` on the
  `TOTAL MONTHLY EARNINGS` and `Gross Earnings (Monthly)` lines. The original fixture is untouched.
- **Command:** `mortgage-extract fixtures/documents/income_sum_matched.txt --mode record`
- **Prediction:** the flag disappears.
- **Actual (`run_sum_matched_live.txt`):** `"stated_monthly_total": 9642.17`, `"consistent": true`, `"discrepancies": []`, `[exit code: 0]`.
- **Difference:** same line items, same model; only the stated total changed, and the discrepancy went away. This confirms the flag comes from the arithmetic check, not from anything else in the document.
- **Side observation:** the net-pay line in this copy is now arithmetically inconsistent (it was not edited), and nothing flagged it, because the validator checks only `total_monthly_income`.
