$ErrorActionPreference = 'Stop'
$root = 'C:\Users\soura\Downloads\Agent Evaluation and Observability with Claude'
$evidenceRoot = Join-Path $root 'evidence'
New-Item -ItemType Directory -Force -Path $evidenceRoot | Out-Null
$shortRoot = 'C:\tmp\evalobs'
New-Item -ItemType Directory -Force -Path $shortRoot | Out-Null

function Ensure-ProjectCopy($name, $sourcePath) {
    $dest = Join-Path $shortRoot $name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $sourcePath $dest
    return $dest
}

# Policy setup
$policySrc = Join-Path $root 'Build a Validated, Routed Insurance Policy Extraction Pipeline\04-hitl-routing\solution'
$policyDir = Ensure-ProjectCopy 'policy_solution' $policySrc
$policyEvidence = Join-Path $evidenceRoot '01-policy-pipeline'
New-Item -ItemType Directory -Force -Path $policyEvidence | Out-Null
$policyVenv = Join-Path $policyDir '.venv'
& 'C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe' -m venv $policyVenv
$policyPy = Join-Path $policyVenv 'Scripts\python.exe'
& $policyPy -m pip install --upgrade pip setuptools wheel
& $policyPy -m pip install -e (Join-Path $policyDir '.[dev]')
& $policyPy -m pytest tests/ -v 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'tests.txt') -Encoding utf8
& $policyPy -m mypy policy_extractor 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'mypy.txt') -Encoding utf8
& $policyPy -m ruff check policy_extractor tests 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'ruff.txt') -Encoding utf8
$calibCode = @'
from policy_extractor.routing import CalibrationLabel, calibration_report
labels = [
    CalibrationLabel(policy_id="POL-1", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-2", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-3", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-4", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-5", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-6", policy_type="home", field="deductible", predicted_confidence=0.90, correct=True),
]
report = calibration_report(labels)
for (ptype, fname), cell in sorted(report.cells.items()):
    print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
print(f"OVERALL brier={report.overall_brier:.3f}")
'@
Set-Content -Path (Join-Path $policyDir 'calib.py') -Value $calibCode -Encoding utf8
Copy-Item -Force (Join-Path $policyDir 'calib.py') (Join-Path $policyEvidence 'calib.py')
& $policyPy (Join-Path $policyDir 'calib.py') 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'calibration.txt') -Encoding utf8
& $policyPy -m pytest tests/test_us01_retry.py -v 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'perturb_retry_tests.txt') -Encoding utf8
$perturbed = @'
from policy_extractor.routing import CalibrationLabel, calibration_report
labels = [
    CalibrationLabel(policy_id="POL-1", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-2", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-3", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-4", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-5", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-6", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-7", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-8", policy_type="home", field="deductible", predicted_confidence=0.90, correct=True),
]
report = calibration_report(labels)
for (ptype, fname), cell in sorted(report.cells.items()):
    print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
print(f"OVERALL brier={report.overall_brier:.3f}")
'@
Set-Content -Path (Join-Path $policyDir 'calib_perturbed.py') -Value $perturbed -Encoding utf8
& $policyPy (Join-Path $policyDir 'calib_perturbed.py') 2>&1 | Tee-Object -FilePath (Join-Path $policyEvidence 'calibration_perturbed.txt') -Encoding utf8

# Mortgage setup
$mortgageSrc = Join-Path $root 'Build a Resilient Mortgage Document Extraction System\04-validate-mathematical-consistency\solution'
$mortgageDir = Ensure-ProjectCopy 'mortgage_solution' $mortgageSrc
$mortgageEvidence = Join-Path $evidenceRoot '02-mortgage'
New-Item -ItemType Directory -Force -Path $mortgageEvidence | Out-Null
$mortgageVenv = Join-Path $mortgageDir '.venv'
& 'C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe' -m venv $mortgageVenv
$mortgagePy = Join-Path $mortgageVenv 'Scripts\python.exe'
& $mortgagePy -m pip install --upgrade pip setuptools wheel
& $mortgagePy -m pip install -e (Join-Path $mortgageDir '.[dev]')
& $mortgagePy -m pytest tests/ -v 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'tests.txt') -Encoding utf8
& $mortgagePy -m mypy mortgage_extractor 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'mypy.txt') -Encoding utf8
& $mortgagePy -m ruff check mortgage_extractor tests 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'ruff.txt') -Encoding utf8
& $mortgagePy -m mortgage_extractor fixtures/documents/appraisal_informal_sqft.txt --mode replay 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'run_appraisal_sqft.txt') -Encoding utf8
& $mortgagePy -m mortgage_extractor fixtures/documents/income_missing_bonus.txt --mode replay 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'run_missing_bonus.txt') -Encoding utf8
& $mortgagePy -m mortgage_extractor fixtures/documents/income_sum_mismatch.txt --mode replay 2>&1 | Tee-Object -FilePath (Join-Path $mortgageEvidence 'run_sum_mismatch.txt') -Encoding utf8

# Supply setup
$supplySrc = Join-Path $root 'Investigate Supply Chain Risk with Multi-Source Synthesis\03-resilient-coordinator\solution'
$supplyDir = Ensure-ProjectCopy 'supply_solution' $supplySrc
$supplyEvidence = Join-Path $evidenceRoot '03-supply-chain'
New-Item -ItemType Directory -Force -Path $supplyEvidence | Out-Null
$supplyVenv = Join-Path $supplyDir '.venv'
& 'C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe' -m venv $supplyVenv
$supplyPy = Join-Path $supplyVenv 'Scripts\python.exe'
& $supplyPy -m pip install --upgrade pip setuptools wheel
& $supplyPy -m pip install -e (Join-Path $supplyDir '.[dev]')
& $supplyPy -m pytest tests/ -q 2>&1 | Tee-Object -FilePath (Join-Path $supplyEvidence 'tests.txt') -Encoding utf8
& $supplyPy -m mypy supply_chain_risk 2>&1 | Tee-Object -FilePath (Join-Path $supplyEvidence 'mypy.txt') -Encoding utf8
& $supplyPy -m ruff check supply_chain_risk tests 2>&1 | Tee-Object -FilePath (Join-Path $supplyEvidence 'ruff.txt') -Encoding utf8
& $supplyPy -m supply_chain_risk.__main__ meridian --offline 2>&1 | Tee-Object -FilePath (Join-Path $supplyEvidence 'briefing_normal.txt') -Encoding utf8
& $supplyPy -m supply_chain_risk.__main__ meridian --offline --simulate-timeout 2>&1 | Tee-Object -FilePath (Join-Path $supplyEvidence 'briefing_timeout.txt') -Encoding utf8

Write-Host 'Evidence collection complete.'
