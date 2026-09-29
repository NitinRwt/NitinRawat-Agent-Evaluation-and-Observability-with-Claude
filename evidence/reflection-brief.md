# Reflection Brief — Evaluation and Observability Capstone

**Name:** Nitin Rawat

**Date:** 2026-09-28

> Sentences marked **[opinion]** are judgment rather than captured evidence. Review and edit before submitting.

---

## 0. Environment

| Field | Value |
|---|---|
| OS & version | Microsoft Windows NT 10.0.26200.0 (Windows 11 Home Single Language); PowerShell 5.1 |
| Python version | Python 3.11.9 (venvs at `C:\ev\{policy,mortgage,supply}`; see `NOTES.md`) |
| Date run | 2026-09-28 |
| Ran any system live? (which) | Yes: System 1 (`pipeline`, `extract` perturbation + baseline) and System 2 (`--mode record` perturbation), via the Vocareum proxy. System 2 main runs used `--mode replay`; System 3 used `--offline` as specified. |

---

## 1. Validated, routed pipeline

| Evidence | Value |
|---|---|
| Passing test count | `45 passed, 3 skipped` (`01-policy-pipeline/tests.txt`; the 3 skipped are `live` tests, which need an API key). An earlier live-key run had 2 live tests fail on a proxy HTTP 400 (`tests_live_proxy_400_earlier.txt`); see `NOTES.md` §3 |
| Routing output file | `01-policy-pipeline/routing_decisions.json` |
| auto_approve / human_review / spot_check counts | 0 / 9 / 0 (`pipeline_run.txt`; plus `"escalations": 1`) |

**1a. Retry boundary.** From `01-policy-pipeline/perturb_blank_field.txt` (premium blanked in a copy of POL-2025-001):

```
2026-09-28 19:18:51,778 INFO HTTP Request: POST https://claude.vocareum.com/v1/messages "HTTP/1.1 200 OK"
2026-09-28 19:18:51,817 INFO validation_failed
{
  "category": "missing_source",
  "detected_pattern": "premium_amount_absent",
  "field": "premium_amount",
  "kind": "escalation",
  "policy_id": "POL-2025-001",
  ...
}
```

> **One** API call (a single `HTTP Request` line). The information isn't in the document, so a retry can't recover it. Retrying only costs calls and latency, and each extra attempt adds pressure on the model to produce a plausible-looking premium, which is worse than an honest escalation. **[opinion]** The same boundary is locked in by `test_ac_01_04_missing_source_halts_immediately` (`assert client.call_count == 1`).

**1b. Reading the router.** POL-2025-002 in `routing_decisions.json`:

> All six confidences are ≥ 0.95 (`"premium_amount": 1.0`, `"policy_type": 1.0`, …), `"fields_below_threshold": []`, `"integration_failures": []`, yet `"decision": "human_review"` with `"reason": "reviewer_disagreement=['coverage_limit', 'deductible']"`. The **reviewer** signal sent it to a human. If only the model's confidence had been trusted, this policy would have been auto-approved with two fields the independent reviewer disputes.

**1c. Where the aggregate lies.** From `01-policy-pipeline/calibration.txt`:

> `umbrella  exclusions      n=2 conf=0.93 acc=0.00 brier=0.865` against `OVERALL brier=0.291`. Adding 20 easy correct auto samples (`calibration_perturbed.txt`) improves the aggregate to `OVERALL brier=0.069`, while the umbrella cell is unchanged at `acc=0.00 brier=0.865`. Slicing by `policy_type × field` shows a cell where the model is confidently wrong every time. A single number, especially one weighted toward the easy, high-volume cell, hides that, and a router tuned on it would auto-approve wrong umbrella exclusions.

---

## 2. Schema-enforced two-pass extraction

| Evidence | Value |
|---|---|
| Passing test count | `25 passed` (`02-mortgage-extraction/tests.txt`) |
| Document run | `fixtures/documents/appraisal_informal_sqft.txt` (`run_appraisal_sqft.txt`); also `income_missing_bonus.txt`, `income_sum_mismatch.txt` |
| Classified type | appraisal (the property section is populated: `"property_type": "single_family"`, `"appraised_value": 410000.0`; income fields null). The CLI's JSON output does not print the classifier's label directly. **[inference]** |

**2a. Two guarantees.** From `02-mortgage-extraction/run_sum_mismatch.txt`:

```
    "consistent": false,
    "discrepancies": [
      {
        "field": "total_monthly_income",
        "calculated": 9642.17,
        "stated": 10892.17,
        "delta": -1250.0
      }
    ]
[exit code: 1]
```

> Tool use guarantees the **shape** (valid JSON, correct types, allowed enums), and this output is perfectly valid JSON. The validator guarantees **internal arithmetic consistency**. Schema can't catch: a well-typed number that doesn't add up (this case). Validator can't catch: a value that is internally consistent but wrong or missing, e.g. `"bonus_ytd": null` in `run_sum_matched_live.txt` although the document shows `3,500.00` YTD, or any field it doesn't check (the net-pay line in the perturbed copy).

**2b. Refusing to fabricate.** From `run_missing_bonus.txt`: `"bonus_monthly": null`.

> Null tells underwriting "the document is silent", which is a fact they can act on (request the document). An invented bonus would inflate qualifying income with no source. The schema allows this through **nullable unions**: `bonus_monthly: float | None = None` (`mortgage_extractor/models.py:58`), so the model has a valid way to say "not stated".

**2c. Normalization.** From `run_appraisal_sqft.txt`: source text "about 2,400 sq ft" → `"gross_living_area_sqft": 2400`.

> At extraction time the model still has the surrounding text to interpret "about", commas and units. Downstream code only sees a string and would need fragile parsing in every consumer. Normalizing once also makes the field typed (`gross_living_area_sqft: int | None`, `models.py:42`), so the validator and routing logic can compare it directly. **[opinion]**

---

## 3. Multi-source synthesis

| Evidence | Value |
|---|---|
| Passing test count | `34 passed, 2 warnings` (`03-supply-chain/tests.txt`) |
| Briefing file | `03-supply-chain/briefing_normal.txt` (timeout run: `briefing_timeout.txt`) |
| Section the conflict landed in | `## Contested` (`on_time_delivery_rate  _[2 sources, conflicting]_  ⚠️ ESCALATE`) |

**3a. Annotate, don't arbitrate.** From `briefing_normal.txt`:

> `95.0 percent — supplier_audit (as of 2026-04-10)` against `78.0 percent — logistics (as of 2026-04-05)`. A reader sees that the supplier's self-reported audit is 17 points rosier than measured logistics data, which is itself a risk signal. A reconciled number (e.g. an average of ~86.5%) would hide both the gap and who is claiming what. **[opinion]**

**3b. Source goes dark.** From `briefing_timeout.txt`:

```
> Sources unavailable: logistics unavailable (timeout)
...
## Incomplete
### late_shipment_count  _[missing source: timeout reading logistics]_
- missing source: timeout reading logistics

### production_capacity_utilization  _[missing source: no source reported this metric]_  ⚠️ ESCALATE
```

> "Unreachable" is labeled `timeout reading logistics` and "nothing to report" is labeled `no source reported this metric`. They're different facts: the first may have data we couldn't get, the second has no data at all. The run finishes (`[exit code: 0]`) because the coordinator records the reader failure as a missing source instead of propagating the exception. Caveat seen in `briefing_diff.txt`: with logistics gone, `on_time_delivery_rate` moved from Contested to Well-Established `_[single source only]_` at 95.0 percent, so the conflict disappeared.

**3c. Dates as a guardrail.** From `briefing_normal.txt`, `defect_rate_ppm`:

> `180.0 ppm — supplier_audit (as of 2026-04-10)` and `190.0 ppm — internal_quality (as of 2026-04-08)`. The values differ, but they're dated two days apart, so the briefing treats them as `_[corroborated across 2 sources]_` measurements over time rather than a contradiction. Without dates, a reader (or the synthesizer) couldn't tell a real disagreement from a metric that moved between measurements.

---

## 4. Synthesis

**4a. One principle.**

> System 1, `routing_decisions.json` / POL-2025-002: the model reported confidence of 0.95–1.0 on every field, so a design that trusted it would have auto-approved. The independent reviewer disagreed on `coverage_limit` and `deductible`, and the router sent the policy to a human.

**4b. Confidence ≠ correctness.**

> System 1. `calibration.txt` shows umbrella exclusions at `conf=0.93 acc=0.00`: the model was as confident there as on cells it got right, and it was wrong every time. Confidence carried no information about correctness for that slice, and the aggregate (`OVERALL brier=0.291`, or `0.069` after adding easy samples) hid it. **[opinion on "mattered most"]**

**4c. Apply it.** 

> Extracting fields from scanned invoices (vendor, line items, tax, total) into an accounts-payable system. Invoices arrive as blurry PDFs in many layouts, and some omit fields such as the PO number. Pattern: Validated retry with escalation. Invoices have a built-in arithmetic check (line items + tax = total), like the mortgage validator that caught a $1,250 mismatch in my run. A missing PO number is a missing-source case, and my policy perturbation showed it should escalate after one call rather than retry until the model invents a value. Instrumentation: (1) escalation rate broken down by reason (e.g. po_number_absent), (2) how often the arithmetic check fails, per vendor, (3) average retries per invoice, (4) a weekly human-checked sample reported as accuracy by vendor × field, not one overall number. My calibration run showed an overall Brier of 0.291 hiding a cell with 0.00 accuracy, so a single vendor could be failing unnoticed.