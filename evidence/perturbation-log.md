# Perturbation Log

For each system, make one deliberate change to an input or configuration, predict the outcome, run
it, and record what actually happened. Full write-ups: `0X-*/perturbation.md`.

---

### System 1 — validated, routed pipeline

- **Change I made (file + what I changed):** Copied `data/policies/POL-2025-001.txt` to a temp folder and blanked the `Total Policy Premium` value (copy saved as `01-policy-pipeline/perturbed_input/POL-2025-001_premium_blanked.txt`; original untouched). Offline second experiment: `calib_perturbed.py` adds 20 correct auto labels to the calibration set.
- **Command I ran:** `policy-extractor extract <temp>\POL-2025-001.txt --policy-id POL-2025-001` (live) and `python calib_perturbed.py`
- **What I predicted:** A single API call followed by a `missing_source` escalation with no invented premium. For calibration: overall Brier improves while umbrella/exclusions stays at acc=0.00.
- **What actually happened (paste the key output line):** `"detected_pattern": "premium_amount_absent"` with `"category": "missing_source"` after one `HTTP Request` line (`perturb_blank_field.txt`). Calibration: `OVERALL brier=0.069` with umbrella still `conf=0.93 acc=0.00 brier=0.865` (`calibration_perturbed.txt`).
- **How this differs from the unperturbed run:** The unperturbed document extracts cleanly: `"premium_amount": 1847.62`, `"retry_count": 0` (`baseline_extract.txt`). Unperturbed calibration: `OVERALL brier=0.291` (`calibration.txt`).

---

### System 2 — schema-enforced two-pass extraction

- **Change I made (file + what I changed):** New fixture `fixtures/documents/income_sum_matched.txt`, a copy of `income_sum_mismatch.txt` with the stated current total changed `10,892.17` → `9,642.17` so it equals the line items (copy in `02-mortgage-extraction/perturbed_input/`). This is the reverse of the suggested starter: the original already mismatches.
- **Command I ran:** `mortgage-extract fixtures/documents/income_sum_matched.txt --mode record` (live)
- **What I predicted:** The consistency flag disappears.
- **What actually happened (paste the key output line):** `"consistent": true,` / `"discrepancies": []` / `[exit code: 0]` (`run_sum_matched_live.txt`)
- **How this differs from the unperturbed run:** The original gives `"consistent": false` with `"delta": -1250.0` and `[exit code: 1]` (`run_sum_mismatch.txt`).

---

### System 3 — multi-source synthesis

- **Change I made (file + what I changed):** Configuration flag `--simulate-timeout`, which makes the logistics reader time out mid-read.
- **Command I ran:** `supply-chain-investigate meridian --offline --simulate-timeout`
- **What I predicted:** The run finishes, and logistics-only metrics move to Incomplete, marked as a timeout.
- **What actually happened (paste the key output line):** `> Sources unavailable: logistics unavailable (timeout)` and `### late_shipment_count  _[missing source: timeout reading logistics]_`, `[exit code: 0]` (`briefing_timeout.txt`). Not predicted: `on_time_delivery_rate` moved from Contested into Well-Established as `_[single source only]_` (95.0 percent, supplier_audit only), and Contested became `_none_`.
- **How this differs from the unperturbed run:** Normally `on_time_delivery_rate` is `_[2 sources, conflicting]_  ⚠️ ESCALATE` (95.0 vs 78.0 percent) and `late_shipment_count` is `11.0 shipments — logistics`. `average_lead_time_days` also drops from 2 sources to 1 (`briefing_diff.txt`).
