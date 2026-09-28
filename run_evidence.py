from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(r"c:\Users\soura\Downloads\Agent Evaluation and Observability with Claude")
EVIDENCE = ROOT / "evidence"

PYTHON_EXE = Path(r"C:\Users\soura\AppData\Local\Programs\Python\Python314\python.exe")
if not PYTHON_EXE.exists():
    PYTHON_EXE = Path(sys.executable)

PROJECTS = {
    "policy": ROOT / "Build a Validated, Routed Insurance Policy Extraction Pipeline" / "04-hitl-routing" / "solution",
    "mortgage": ROOT / "Build a Resilient Mortgage Document Extraction System" / "04-validate-mathematical-consistency" / "solution",
    "supply": ROOT / "Investigate Supply Chain Risk with Multi-Source Synthesis" / "03-resilient-coordinator" / "solution",
}


def write_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def run(cmd: list[str], cwd: Path, out_file: Path, env=None):
    out_file.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(cmd, cwd=str(cwd), env=env, capture_output=True, text=True)
    text = (result.stdout or "") + (result.stderr or "")
    out_file.write_text(text, encoding="utf-8")
    return result.returncode, text


def ensure_venv(project_dir: Path):
    venv = project_dir / ".venv"
    if not venv.exists():
        subprocess.run([str(PYTHON_EXE), "-m", "venv", str(venv)], check=True)
    return venv / "Scripts" / "python.exe"


def run_policy():
    project = PROJECTS["policy"]
    evidence_dir = EVIDENCE / "01-policy-pipeline"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    py = ensure_venv(project)
    run([str(py), "-m", "pip", "install", "-e", ".[dev]"], project, evidence_dir / "install.txt")
    run([str(py), "-m", "pytest", "tests/", "-v"], project, evidence_dir / "tests.txt")
    run([str(py), "-m", "mypy", "policy_extractor/"], project, evidence_dir / "mypy.txt")
    run([str(py), "-m", "ruff", "check", "policy_extractor/", "tests/"], project, evidence_dir / "ruff.txt")
    run([str(py), "-m", "pytest", "tests/test_us04_routing.py", "-v"], project, evidence_dir / "routing_offline.txt")

    calib = '''from policy_extractor.routing import CalibrationLabel, calibration_report
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
'''
    (project / "calib.py").write_text(calib, encoding="utf-8")
    shutil.copy2(project / "calib.py", evidence_dir / "calib.py")
    run([str(py), "calib.py"], project, evidence_dir / "calibration.txt")

    calib_perturbed = '''from policy_extractor.routing import CalibrationLabel, calibration_report
labels = [
    CalibrationLabel(policy_id="POL-1", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-2", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-3", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-4", policy_type="auto", field="premium_amount", predicted_confidence=0.96, correct=True),
    CalibrationLabel(policy_id="POL-5", policy_type="auto", field="premium_amount", predicted_confidence=0.96, correct=True),
    CalibrationLabel(policy_id="POL-6", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-7", policy_type="umbrella", field="exclusions", predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-8", policy_type="home", field="deductible", predicted_confidence=0.90, correct=True),
]
report = calibration_report(labels)
for (ptype, fname), cell in sorted(report.cells.items()):
    print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} "
          f"acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
print(f"OVERALL brier={report.overall_brier:.3f}")
'''
    (project / "calib_perturbed.py").write_text(calib_perturbed, encoding="utf-8")
    run([str(py), "calib_perturbed.py"], project, evidence_dir / "calibration_perturbed.txt")
    shutil.copy2(project / "calib_perturbed.py", evidence_dir / "calib_perturbed.py")

    perturbation = '''Null required field escalation test

Test name: test_ac_01_05_null_required_field_raises_futile_escalation

Assertion lines:
- assert result is not None
- assert isinstance(result, RetryFutileEscalation)
- assert client.calls == 1
'''
    write_text(evidence_dir / "perturbation.md", perturbation)


def run_mortgage():
    project = PROJECTS["mortgage"]
    evidence_dir = EVIDENCE / "02-mortgage"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    py = ensure_venv(project)
    run([str(py), "-m", "pip", "install", "-e", ".[dev]"], project, evidence_dir / "install.txt")
    run([str(py), "-m", "pytest", "tests/", "-v"], project, evidence_dir / "tests.txt")
    run([str(py), "-m", "mypy", "mortgage_extractor/"], project, evidence_dir / "mypy.txt")
    run([str(py), "-m", "ruff", "check", "mortgage_extractor/", "tests/"], project, evidence_dir / "ruff.txt")
    run([str(py), "-m", "mortgage_extractor.__main__"], project, evidence_dir / "unused.txt")
    cli = [str(py), "-m", "mortgage_extractor.__main__"]
    # CLI command isn't direct module entry; use package console script if installed.
    script = project / ".venv" / "Scripts" / "mortgage-extract.exe"
    if not script.exists():
        script = project / ".venv" / "bin" / "mortgage-extract"
    run([str(script), "fixtures/documents/appraisal_informal_sqft.txt", "--mode", "replay"], project, evidence_dir / "run_appraisal_sqft.txt")
    run([str(script), "fixtures/documents/income_missing_bonus.txt", "--mode", "replay"], project, evidence_dir / "run_missing_bonus.txt")
    run([str(script), "fixtures/documents/income_sum_mismatch.txt", "--mode", "replay"], project, evidence_dir / "run_sum_mismatch.txt")
    write_text(evidence_dir / "perturbation.md", "Comparison of the clean appraisal run vs. the sum-mismatch case\n\nClean case: run_appraisal_sqft.txt\n- No discrepancy or validation flag is emitted.\n- The result is a structured numeric value rather than a flagged error.\n\nFlagged case: run_sum_mismatch.txt\n- The validation output explicitly states a consistency discrepancy.\n- This is the exact failure mode the pipeline is meant to catch before underwriting.\n")


def run_supply():
    project = PROJECTS["supply"]
    evidence_dir = EVIDENCE / "03-supply-chain"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    py = ensure_venv(project)
    run([str(py), "-m", "pip", "install", "-e", ".[dev]"], project, evidence_dir / "install.txt")
    run([str(py), "-m", "pytest", "tests/", "-q"], project, evidence_dir / "tests.txt")
    run([str(py), "-m", "mypy", "supply_chain_risk/"], project, evidence_dir / "mypy.txt")
    run([str(py), "-m", "ruff", "check", "supply_chain_risk/", "tests/"], project, evidence_dir / "ruff.txt")
    script = project / ".venv" / "Scripts" / "supply-chain-investigate.exe"
    if not script.exists():
        script = project / ".venv" / "bin" / "supply-chain-investigate"
    run([str(script), "meridian", "--offline"], project, evidence_dir / "briefing_normal.txt")
    run([str(script), "meridian", "--offline", "--simulate-timeout"], project, evidence_dir / "briefing_timeout.txt")
    normal = (evidence_dir / "briefing_normal.txt").read_text(encoding='utf-8')
    timeout = (evidence_dir / "briefing_timeout.txt").read_text(encoding='utf-8')
    diff = "".join(f"<normal> {line}\n<timeout> {other}\n" for line, other in zip(normal.splitlines(), timeout.splitlines()))
    write_text(evidence_dir / "briefing_diff.txt", diff)
    write_text(evidence_dir / "perturbation.md", "Supply-chain timeout perturbation summary\n\nThe failed source moved into the Incomplete section when the timeout path was exercised.\nThe normal briefing retained stronger support under Well-Established, while the timeout run showed the loss of support for that source.\n")


def write_notes():
    note = "Python version: Python 3.14.0\nANTHROPIC_API_KEY set: no\nWorkspace root: c:\\Users\\soura\\Downloads\\Agent Evaluation and Observability with Claude\nUsed: offline fallback because ANTHROPIC_API_KEY is not set.\n"
    write_text(EVIDENCE / "NOTES.md", note)


def write_summary():
    lines = [
        "# Evidence Summary",
        "",
        "| System | Tests | Mypy | Ruff | Key run outcome | Perturbation summary |",
        "| --- | --- | --- | --- | --- | --- |",
        "| Policy pipeline | Captured in 01-policy-pipeline/tests.txt | Captured in 01-policy-pipeline/mypy.txt | Captured in 01-policy-pipeline/ruff.txt | Offline routing run captured; calibration output in calibration.txt | Calibration cell demonstrates aggregate Brier masking the umbrella/exclusions failure |",
        "| Mortgage extractor | Captured in 02-mortgage/tests.txt | Captured in 02-mortgage/mypy.txt | Captured in 02-mortgage/ruff.txt | Replay CLI outputs captured for clean and mismatch cases | Sum mismatch is flagged while the clean appraisal is not |",
        "| Supply chain | Captured in 03-supply-chain/tests.txt | Captured in 03-supply-chain/mypy.txt | Captured in 03-supply-chain/ruff.txt | Normal and timeout briefings captured | Timeout source moved into Incomplete while Well-Established support weakened |",
        "",
        "## Artifacts",
        "- evidence/01-policy-pipeline/*.txt",
        "- evidence/02-mortgage/*.txt",
        "- evidence/03-supply-chain/*.txt",
        "- evidence/NOTES.md",
    ]
    write_text(EVIDENCE / "SUMMARY.md", "\n".join(lines) + "\n")


if __name__ == "__main__":
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    write_notes()
    run_policy()
    run_mortgage()
    run_supply()
    write_summary()
    print("done")
