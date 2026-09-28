# Runs COPILOT_TASK.md sections 1-4 and captures every output into evidence\.
# Layout follows "Project-Evaluation and Observability Project\README.md" (02-mortgage-extraction etc.).
# PowerShell 5.1 compatible: Tee-Object has no -Encoding there, so captures go through Out-File -Encoding utf8.
# Venvs live under C:\ev\ because the workspace path is long enough that packages inside a
# project-local .venv exceed Windows' 260-char MAX_PATH and install incompletely.
# The API key is read from the environment only; it is never written to disk.
$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
$Py311 = "C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe"
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Policy   = Join-Path $Root "Build a Validated, Routed Insurance Policy Extraction Pipeline\04-hitl-routing\solution"
$Mortgage = Join-Path $Root "Build a Resilient Mortgage Document Extraction System\04-validate-mathematical-consistency\solution"
$Supply   = Join-Path $Root "Investigate Supply Chain Risk with Multi-Source Synthesis\03-resilient-coordinator\solution"
$V1 = "C:\ev\policy\Scripts"
$V2 = "C:\ev\mortgage\Scripts"
$V3 = "C:\ev\supply\Scripts"
$Ev  = Join-Path $Root "evidence"
$E1  = Join-Path $Ev "01-policy-pipeline"
$E2  = Join-Path $Ev "02-mortgage-extraction"
$E3  = Join-Path $Ev "03-supply-chain"
$Notes = Join-Path $Ev "NOTES.md"
foreach ($d in $E1, $E2, $E3) { New-Item -ItemType Directory -Force $d | Out-Null }

function Note([string]$Text) { $Text | Out-File -FilePath $Notes -Append -Encoding utf8 }

# Run a native command, show output, save UTF-8 capture with a trailing exit code line.
function Capture([string]$OutFile, [string]$Exe, [string[]]$CmdArgs) {
    Write-Host ">>> $Exe $($CmdArgs -join ' ')  ->  $OutFile" -ForegroundColor Cyan
    $lines = & $Exe @CmdArgs 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
    }
    $code = $LASTEXITCODE
    $lines = @($lines) + "[exit code: $code]"
    $lines | Out-File -FilePath $OutFile -Encoding utf8
    $lines | ForEach-Object { Write-Host $_ }
    return $code
}

# ---------------- 1. Setup ----------------
$key = if ($env:ANTHROPIC_API_KEY) { "yes" } else { "no" }
Note ""
Note "## Run $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Note "- OS: $([System.Environment]::OSVersion.VersionString); PowerShell $($PSVersionTable.PSVersion)"
Note "- Default ``python --version``: $(& python --version 2>&1) (below 3.11, so not used)"
Note "- Venv interpreter: $(& $Py311 --version 2>&1) at $Py311"
Note "- ANTHROPIC_API_KEY set: $key; ANTHROPIC_BASE_URL: $(if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL } else { 'default' })"
Note "- Venvs at C:\ev\{policy,mortgage,supply}: project-local .venv hit Windows MAX_PATH (ModuleNotFoundError: anthropic.types.usage)."

$pairs = @(@($Policy, "C:\ev\policy", "install-policy.txt"), @($Mortgage, "C:\ev\mortgage", "install-mortgage.txt"), @($Supply, "C:\ev\supply", "install-supply.txt"))
foreach ($p in $pairs) {
    Push-Location $p[0]
    if (-not (Test-Path "$($p[1])\Scripts\python.exe")) { & $Py311 -m venv $p[1] }
    $c = Capture (Join-Path $Ev $p[2]) "$($p[1])\Scripts\python.exe" @("-m", "pip", "install", "-e", ".[dev]")
    Note "- pip install -e .[dev] into $($p[1]): exit $c (log: $($p[2]))"
    Pop-Location
}

# ---------------- 2. System 1: policy pipeline ----------------
Push-Location $Policy
Capture "$E1\tests.txt" "$V1\pytest.exe" @("tests/", "-v") | Out-Null
Capture "$E1\mypy.txt"  "$V1\mypy.exe"   @("policy_extractor/") | Out-Null
Capture "$E1\ruff.txt"  "$V1\ruff.exe"   @("check", "policy_extractor/", "tests/") | Out-Null
if ($key -eq "yes") {
    Capture "$E1\pipeline_run.txt" "$V1\policy-extractor.exe" @("pipeline", "data/policies/", "--routing-out", "routing_decisions.json", "--seed", "42") | Out-Null
    if (Test-Path routing_decisions.json) { Copy-Item routing_decisions.json $E1 -Force }
}
Capture "$E1\routing_offline.txt" "$V1\pytest.exe" @("tests/test_us04_routing.py", "-v") | Out-Null
Capture "$E1\calibration.txt"           "$V1\python.exe" @("calib.py") | Out-Null
Capture "$E1\calibration_perturbed.txt" "$V1\python.exe" @("calib_perturbed.py") | Out-Null
Copy-Item calib.py, calib_perturbed.py $E1 -Force
Capture "$E1\perturb_retry_tests.txt" "$V1\pytest.exe" @("tests/test_us01_retry.py", "-v") | Out-Null
Pop-Location

# ---------------- 3. System 2: mortgage ----------------
Push-Location $Mortgage
Capture "$E2\tests.txt" "$V2\pytest.exe" @("tests/", "-v") | Out-Null
Capture "$E2\mypy.txt"  "$V2\mypy.exe"   @("mortgage_extractor/") | Out-Null
Capture "$E2\ruff.txt"  "$V2\ruff.exe"   @("check", "mortgage_extractor/", "tests/") | Out-Null
Capture "$E2\run_appraisal_sqft.txt" "$V2\mortgage-extract.exe" @("fixtures/documents/appraisal_informal_sqft.txt", "--mode", "replay") | Out-Null
Capture "$E2\run_missing_bonus.txt"  "$V2\mortgage-extract.exe" @("fixtures/documents/income_missing_bonus.txt", "--mode", "replay") | Out-Null
Capture "$E2\run_sum_mismatch.txt"   "$V2\mortgage-extract.exe" @("fixtures/documents/income_sum_mismatch.txt", "--mode", "replay") | Out-Null
Capture "$E2\validator_tests.txt" "$V2\pytest.exe" @("tests/test_us04_validator.py", "-v") | Out-Null
Pop-Location

# ---------------- 4. System 3: supply chain ----------------
Push-Location $Supply
Capture "$E3\tests.txt" "$V3\pytest.exe" @("tests/", "-q") | Out-Null
Capture "$E3\mypy.txt"  "$V3\mypy.exe"   @("supply_chain_risk/") | Out-Null
Capture "$E3\ruff.txt"  "$V3\ruff.exe"   @("check", "supply_chain_risk/", "tests/") | Out-Null
Capture "$E3\briefing_normal.txt"  "$V3\supply-chain-investigate.exe" @("meridian", "--offline") | Out-Null
Capture "$E3\briefing_timeout.txt" "$V3\supply-chain-investigate.exe" @("meridian", "--offline", "--simulate-timeout") | Out-Null
Compare-Object (Get-Content "$E3\briefing_normal.txt") (Get-Content "$E3\briefing_timeout.txt") |
    Out-File "$E3\briefing_diff.txt" -Encoding utf8
Pop-Location

# README layout asks for static-checks.txt = mypy + ruff.
foreach ($e in $E1, $E2, $E3) {
    (@("=== mypy ===") + (Get-Content "$e\mypy.txt") + @("", "=== ruff ===") + (Get-Content "$e\ruff.txt")) |
        Out-File "$e\static-checks.txt" -Encoding utf8
}
Note "- Path used: $(if ($key -eq 'yes') { 'live API for System 1 pipeline run; other runs offline/replay as specified' } else { 'offline fallback (no ANTHROPIC_API_KEY)' })"
Write-Host "DONE" -ForegroundColor Green
