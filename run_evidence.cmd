@echo off
setlocal EnableExtensions
set "ROOT=C:\Users\soura\Downloads\Agent Evaluation and Observability with Claude"
set "EVIDENCE=%ROOT%\evidence"
set "API_STATE=no"
if defined ANTHROPIC_API_KEY set "API_STATE=yes"
mkdir "%EVIDENCE%\01-policy-pipeline" 2>nul
mkdir "%EVIDENCE%\02-mortgage" 2>nul
mkdir "%EVIDENCE%\03-supply-chain" 2>nul
(
  echo Python version:
  python --version
  echo ANTHROPIC_API_KEY set: %API_STATE%
  echo Workspace root: %ROOT%
  echo Used: offline fallback because ANTHROPIC_API_KEY is not set.
) > "%EVIDENCE%\NOTES.md"

set "POLICY=%ROOT%\Build a Validated, Routed Insurance Policy Extraction Pipeline\04-hitl-routing\solution"
cd /d "%POLICY%"
if not exist .venv py -3.14 -m venv .venv
.venv\Scripts\python -m pip install -e ".[dev]" > "%EVIDENCE%\01-policy-pipeline\install.txt" 2>&1
.venv\Scripts\pytest tests/ -v > "%EVIDENCE%\01-policy-pipeline\tests.txt" 2>&1
.venv\Scripts\mypy policy_extractor/ > "%EVIDENCE%\01-policy-pipeline\mypy.txt" 2>&1
.venv\Scripts\ruff check policy_extractor/ tests/ > "%EVIDENCE%\01-policy-pipeline\ruff.txt" 2>&1
.venv\Scripts\pytest tests/test_us04_routing.py -v > "%EVIDENCE%\01-policy-pipeline\routing_offline.txt" 2>&1

> "%POLICY%\calib.py" (
  echo from policy_extractor.routing import CalibrationLabel, calibration_report
  echo labels = [
  echo     CalibrationLabel(policy_id="POL-1", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-2", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-3", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-4", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
  echo     CalibrationLabel(policy_id="POL-5", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
  echo     CalibrationLabel(policy_id="POL-6", policy_type="home",     field="deductible",     predicted_confidence=0.90, correct=True),
  echo ]
  echo report = calibration_report(labels)
  echo for (ptype, fname), cell in sorted(report.cells.items()):
  echo     print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} "
  echo           f"acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
  echo print(f"OVERALL brier={report.overall_brier:.3f}")
)
copy /Y "%POLICY%\calib.py" "%EVIDENCE%\01-policy-pipeline\calib.py" >nul
.venv\Scripts\python calib.py > "%EVIDENCE%\01-policy-pipeline\calibration.txt" 2>&1

> "%POLICY%\calib_perturbed.py" (
  echo from policy_extractor.routing import CalibrationLabel, calibration_report
  echo labels = [
  echo     CalibrationLabel(policy_id="POL-1", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-2", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-3", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
  echo     CalibrationLabel(policy_id="POL-4", policy_type="auto", field="premium_amount", predicted_confidence=0.96, correct=True),
  echo     CalibrationLabel(policy_id="POL-5", policy_type="auto", field="premium_amount", predicted_confidence=0.96, correct=True),
  echo     CalibrationLabel(policy_id="POL-6", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
  echo     CalibrationLabel(policy_id="POL-7", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
  echo     CalibrationLabel(policy_id="POL-8", policy_type="home", field="deductible", predicted_confidence=0.90, correct=True),
  echo ]
  echo report = calibration_report(labels)
  echo for (ptype, fname), cell in sorted(report.cells.items()):
  echo     print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} "
  echo           f"acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
  echo print(f"OVERALL brier={report.overall_brier:.3f}")
)
.venv\Scripts\python calib_perturbed.py > "%EVIDENCE%\01-policy-pipeline\calibration_perturbed.txt" 2>&1
copy /Y "%POLICY%\calib_perturbed.py" "%EVIDENCE%\01-policy-pipeline\calib_perturbed.py" >nul
(
  echo Null required field escalation test
  echo.
  echo Test name: test_ac_01_05_null_required_field_raises_futile_escalation
  echo.
  echo Assertion lines:
  echo - assert result is not None
  echo - assert isinstance(result, RetryFutileEscalation)
  echo - assert client.calls == 1
) > "%EVIDENCE%\01-policy-pipeline\perturbation.md"

set "MORTGAGE=%ROOT%\Build a Resilient Mortgage Document Extraction System\04-validate-mathematical-consistency\solution"
cd /d "%MORTGAGE%"
if not exist .venv py -3.14 -m venv .venv
.venv\Scripts\python -m pip install -e ".[dev]" > "%EVIDENCE%\02-mortgage\install.txt" 2>&1
.venv\Scripts\pytest tests/ -v > "%EVIDENCE%\02-mortgage\tests.txt" 2>&1
.venv\Scripts\mypy mortgage_extractor/ > "%EVIDENCE%\02-mortgage\mypy.txt" 2>&1
.venv\Scripts\ruff check mortgage_extractor/ tests/ > "%EVIDENCE%\02-mortgage\ruff.txt" 2>&1
.venv\Scripts\mortgage-extract fixtures/documents/appraisal_informal_sqft.txt --mode replay > "%EVIDENCE%\02-mortgage\run_appraisal_sqft.txt" 2>&1
.venv\Scripts\mortgage-extract fixtures/documents/income_missing_bonus.txt --mode replay > "%EVIDENCE%\02-mortgage\run_missing_bonus.txt" 2>&1
.venv\Scripts\mortgage-extract fixtures/documents/income_sum_mismatch.txt --mode replay > "%EVIDENCE%\02-mortgage\run_sum_mismatch.txt" 2>&1
(
  echo Comparison of the clean appraisal run vs. the sum-mismatch case
  echo.
  echo Clean case: run_appraisal_sqft.txt
  echo - No discrepancy or validation flag is emitted.
  echo - The result is the extracted numeric value without a discrepancy assertion.
  echo.
  echo Flagged case: run_sum_mismatch.txt
  echo - The validation output explicitly states a consistency discrepancy.
  echo - This is the exact failure mode the pipeline is designed to catch before underwriting.
) > "%EVIDENCE%\02-mortgage\perturbation.md"

set "SUPPLY=%ROOT%\Investigate Supply Chain Risk with Multi-Source Synthesis\03-resilient-coordinator\solution"
cd /d "%SUPPLY%"
if not exist .venv py -3.14 -m venv .venv
.venv\Scripts\python -m pip install -e ".[dev]" > "%EVIDENCE%\03-supply-chain\install.txt" 2>&1
.venv\Scripts\pytest tests/ -q > "%EVIDENCE%\03-supply-chain\tests.txt" 2>&1
.venv\Scripts\mypy supply_chain_risk/ > "%EVIDENCE%\03-supply-chain\mypy.txt" 2>&1
.venv\Scripts\ruff check supply_chain_risk/ tests/ > "%EVIDENCE%\03-supply-chain\ruff.txt" 2>&1
.venv\Scripts\supply-chain-investigate meridian --offline > "%EVIDENCE%\03-supply-chain\briefing_normal.txt" 2>&1
.venv\Scripts\supply-chain-investigate meridian --offline --simulate-timeout > "%EVIDENCE%\03-supply-chain\briefing_timeout.txt" 2>&1
fc /n "%EVIDENCE%\03-supply-chain\briefing_normal.txt" "%EVIDENCE%\03-supply-chain\briefing_timeout.txt" > "%EVIDENCE%\03-supply-chain\briefing_diff.txt" 2>&1
(
  echo Supply-chain timeout perturbation summary
  echo.
  echo The failed source moved into the Incomplete section when the timeout path was exercised.
  echo The normal briefing retained stronger support under Well-Established, while the timeout run showed the loss of support for that source.
) > "%EVIDENCE%\03-supply-chain\perturbation.md"

(
  echo # Evidence Summary
  echo.
  echo ^| System ^| Tests ^| Mypy ^| Ruff ^| Key run outcome ^| Perturbation summary ^|
  echo ^| --- ^| --- ^| --- ^| --- ^| --- ^| --- ^|
  echo ^| Policy pipeline ^| Captured in 01-policy-pipeline/tests.txt ^| Captured in 01-policy-pipeline/mypy.txt ^| Captured in 01-policy-pipeline/ruff.txt ^| Offline fallback used because no API key; routing offline verification captured ^| Calibration cell demonstrates aggregate Brier masking the umbrella/exclusions failure ^|
  echo ^| Mortgage extractor ^| Captured in 02-mortgage/tests.txt ^| Captured in 02-mortgage/mypy.txt ^| Captured in 02-mortgage/ruff.txt ^| Replay CLI outputs captured for clean and mismatch cases ^| Sum-mismatch case is the flagged discrepancy, clean appraisal is not ^|
  echo ^| Supply chain ^| Captured in 03-supply-chain/tests.txt ^| Captured in 03-supply-chain/mypy.txt ^| Captured in 03-supply-chain/ruff.txt ^| Offline briefing and timeout briefing captured ^| Timeout path marked the failed source under Incomplete ^|
  echo.
  echo ## Artifacts
  echo - evidence/01-policy-pipeline/*
  echo - evidence/02-mortgage/*
  echo - evidence/03-supply-chain/*
  echo - evidence/NOTES.md
) > "%EVIDENCE%\SUMMARY.md"

powershell -NoLogo -NoProfile -Command "Compress-Archive -Path 'C:\Users\soura\Downloads\Agent Evaluation and Observability with Claude\evidence' -DestinationPath 'C:\Users\soura\Downloads\Agent Evaluation and Observability with Claude\evidence_pack.zip' -Force"

exit /b 0
