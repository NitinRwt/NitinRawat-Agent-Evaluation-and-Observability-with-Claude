# COPILOT TASK: Run, Capture, Perturb, Reflect (3 AI Systems)

> **Instructions for the AI agent (GitHub Copilot / agent mode):**
> Execute this runbook top to bottom. Run every command yourself in the terminal. **Never invent output**. Every number you write in a reflection must come from a captured file. If a command fails, record the failure output, try to fix the cause (missing venv, wrong path, encoding), re-run, and note what you did in `evidence/NOTES.md`.
> Tick the checkboxes in this file as you complete steps.

---

## 0. Context

This workspace contains three Python projects (find their folders; likely names contain `policy`, `mortgage`, `supply_chain`):

| # | System | Package | CLI |
|---|--------|---------|-----|
| 1 | Validated, routed policy pipeline | `policy_extractor` | `policy-extractor` |
| 2 | Schema-enforced two-pass mortgage extraction | `mortgage_extractor` | `mortgage-extract` |
| 3 | Multi-source supply-chain synthesis | `supply_chain_risk` | `supply-chain-investigate` |

Every system goes through four phases: **reproduce → run → perturb → reflect**.

**Read the starter `README.md` first.** If it defines an evidence-pack folder layout, use that layout and adapt the paths below. Otherwise use the default layout in section 1.

### Platform rules
- **Windows (PowerShell):** use `.venv\Scripts\<tool>`. Capture with `| Tee-Object -FilePath <path> -Encoding utf8`. Heredocs (`<<'PY'`) don't work, so write Python to a `.py` file instead.
- **macOS/Linux:** use `.venv/bin/<tool>` and `| tee <path>`.
- Also capture stderr: in PowerShell append `2>&1` before the pipe; in bash use `2>&1 | tee`.
- Detect the OS first and use the matching syntax throughout.

---

## 1. Setup

- [x] Create the evidence pack at the workspace root:
```
evidence/
  01-policy-pipeline/
  02-mortgage/
  03-supply-chain/
  NOTES.md
  SUMMARY.md
```
- [x] Confirm Python ≥ 3.11: `python --version` → save to `evidence/NOTES.md`.
- [x] In **each** project folder:
```powershell
python -m venv .venv
.venv\Scripts\pip install -e ".[dev]"
```
- [x] Record whether `ANTHROPIC_API_KEY` is set (`$env:ANTHROPIC_API_KEY` non-empty? yes/no, **never print the key**) in `NOTES.md`. This decides the live vs offline path in System 1.

---

## 2. System 1: Policy pipeline

Run from the policy project folder. `$E = "<root>\evidence\01-policy-pipeline"`.

- [x] Tests: `.venv\Scripts\pytest tests/ -v 2>&1 | Tee-Object -FilePath $E\tests.txt -Encoding utf8`
  Expect **45 passed**. One `live` test skipped without a key is OK.
- [x] Types: `.venv\Scripts\mypy policy_extractor/ 2>&1 | Tee-Object -FilePath $E\mypy.txt -Encoding utf8`
- [x] Lint: `.venv\Scripts\ruff check policy_extractor/ tests/ 2>&1 | Tee-Object -FilePath $E\ruff.txt -Encoding utf8`
- [x] **If API key present:**
  `.venv\Scripts\policy-extractor pipeline data/policies/ --routing-out routing_decisions.json --seed 42 2>&1 | Tee-Object -FilePath $E\pipeline_run.txt -Encoding utf8`
  Then copy `routing_decisions.json` into `$E\`. Record the auto_approve / human_review / spot_check counts.
- [x] **If NO API key (fallback):**
  `.venv\Scripts\pytest tests/test_us04_routing.py -v 2>&1 | Tee-Object -FilePath $E\routing_offline.txt -Encoding utf8`
- [x] Calibration report: create `calib.py` in the project folder with this exact content:
```python
from policy_extractor.routing import CalibrationLabel, calibration_report
labels = [
    CalibrationLabel(policy_id="POL-1", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-2", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-3", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-4", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-5", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-6", policy_type="home",     field="deductible",     predicted_confidence=0.90, correct=True),
]
report = calibration_report(labels)
for (ptype, fname), cell in sorted(report.cells.items()):
    print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} "
          f"acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
print(f"OVERALL brier={report.overall_brier:.3f}")
```
  Run: `.venv\Scripts\python calib.py 2>&1 | Tee-Object -FilePath $E\calibration.txt -Encoding utf8`
  Expect: umbrella/exclusions **acc=0.00 at conf=0.93**, while OVERALL brier stays moderate. Copy `calib.py` into `$E\` too.

### Perturbation (System 1)
- [x] Starter: `.venv\Scripts\pytest tests/test_us01_retry.py -v 2>&1 | Tee-Object -FilePath $E\perturb_retry_tests.txt -Encoding utf8`
  Open `tests/test_us01_retry.py` and find the test asserting that a **null required field escalates with exactly one API call**. Record the test name and the assertion lines in `$E\perturbation.md`.
- [x] Own experiment (preferred, offline): copy `calib.py` to `calib_perturbed.py` and change the labels (e.g. add more correct `auto` samples and show the overall Brier improving while the umbrella cell stays at 0.00). This demonstrates that aggregate metrics can hide a failing cell. Capture to `$E\calibration_perturbed.txt`.
- [x] If API key present: copy one policy doc from `data/policies/` to a temp folder, blank a required field, and run `policy-extractor extract <copied-file>`. Capture to `$E\perturb_blank_field.txt`. **Do not modify the original data.**

---

## 3. System 2: Mortgage extractor

Run from the mortgage project folder. `$E = "<root>\evidence\02-mortgage"`.

- [x] `.venv\Scripts\pytest tests/ -v` → `$E\tests.txt`
- [x] `.venv\Scripts\mypy mortgage_extractor/` → `$E\mypy.txt`
- [x] `.venv\Scripts\ruff check mortgage_extractor/ tests/` → `$E\ruff.txt`
- [x] `.venv\Scripts\mortgage-extract fixtures/documents/appraisal_informal_sqft.txt --mode replay` → `$E\run_appraisal_sqft.txt`
  Expect: "about 2,400 sq ft" normalized to an **integer**.
- [x] `.venv\Scripts\mortgage-extract fixtures/documents/income_missing_bonus.txt --mode replay` → `$E\run_missing_bonus.txt`
  Expect: missing field returned as **null**, not invented.
- [x] `.venv\Scripts\mortgage-extract fixtures/documents/income_sum_mismatch.txt --mode replay` → `$E\run_sum_mismatch.txt`
  Expect: **consistency discrepancy** reported.

### Perturbation (System 2)
- [x] Write `$E\perturbation.md` contrasting `run_sum_mismatch.txt` (flagged) with `run_appraisal_sqft.txt` (clean). Quote the exact lines showing the flag and the absence of one.
- [x] Own experiment (preferred): read the source to find where the consistency check lives (search for `sum`, `consistency`, `discrepancy`, `tolerance`). Explain the tolerance or rule. If a unit test covers it, run that single test and capture it.
- [x] If API key present: copy `income_sum_mismatch.txt` to a new fixture, edit the stated total so it **matches** the line items, and run with `--mode record`. Capture and check whether the flag disappears. Don't overwrite original fixtures.

---

## 4. System 3: Supply chain

Run from the supply-chain project folder. `$E = "<root>\evidence\03-supply-chain"`.
Note: the first run downloads a ~90 MB embedding model. Let it finish; don't cancel.

- [x] `.venv\Scripts\pytest tests/ -q` → `$E\tests.txt`
- [x] `.venv\Scripts\mypy supply_chain_risk/` → `$E\mypy.txt`
- [x] `.venv\Scripts\ruff check supply_chain_risk/ tests/` → `$E\ruff.txt`
- [x] `.venv\Scripts\supply-chain-investigate meridian --offline` → `$E\briefing_normal.txt`
  Verify: sections **Well-Established / Contested / Incomplete**. Logistics are listed. The on-time-delivery conflict (**~95% vs ~78%**) appears with both values attributed and dated.
- [x] `.venv\Scripts\supply-chain-investigate meridian --offline --simulate-timeout` → `$E\briefing_timeout.txt`
  Verify: it completes, and the failed source is marked under **Incomplete**.

### Perturbation (System 3)
- [x] Diff the two briefings:
  `Compare-Object (Get-Content $E\briefing_normal.txt) (Get-Content $E\briefing_timeout.txt) | Out-File $E\briefing_diff.txt -Encoding utf8`
  (bash: `diff briefing_normal.txt briefing_timeout.txt > briefing_diff.txt`)
- [x] Write `$E\perturbation.md`: which source failed, what moved into Incomplete, and whether any Well-Established claim lost support.

---

## 5. Reflect

For each system, write `evidence/0X-.../reflection.md` (~150–300 words), with these sections:

1. **What the system guarantees**: the safeguard it demonstrates.
2. **Evidence**: cite the file name plus the exact quoted value (e.g. `calibration.txt: umbrella exclusions acc=0.00 conf=0.93`).
3. **What the perturbation showed.**
4. **Where it could still fail**: a limitation or blind spot.

Key insight to include for System 1: **the overall Brier score hides the badly calibrated umbrella/exclusions cell**, so routing on aggregate confidence would auto-approve wrong answers.

> Agent: draft these from the captured outputs only. Mark any sentence that states opinion rather than evidence so the human can edit it.

---

## 6. Final verification and submission

- [x] Every `.txt` capture is non-empty and readable UTF-8 (not UTF-16 garbage). Re-capture any that aren't.
- [x] Every value quoted in a reflection is found verbatim in the cited file. Verify with `Select-String -Path <file> -Pattern "<value>"`.
- [x] Write `evidence/SUMMARY.md`: a table with one row per system (tests passed/skipped, mypy result, ruff result, key run outcome, perturbation summary), plus a list of all artifacts.
- [x] Record in `NOTES.md` whether the live API or the offline fallback was used.
- [x] Zip it: `Compress-Archive -Path evidence -DestinationPath evidence_pack.zip -Force`

**Done when every checkbox above is ticked and `evidence_pack.zip` exists.**
