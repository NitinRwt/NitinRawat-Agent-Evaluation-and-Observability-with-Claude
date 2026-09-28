from pathlib import Path
import os, shutil, subprocess, sys

root = Path(r'c:\Users\soura\Downloads\Agent Evaluation and Observability with Claude')
out_root = root / 'evidence' / '01-policy-pipeline'
out_root.mkdir(parents=True, exist_ok=True)
short_root = Path(r'c:\tmp\evalobs')
short_root.mkdir(exist_ok=True)
project_src = root / 'Build a Validated, Routed Insurance Policy Extraction Pipeline' / '04-hitl-routing' / 'solution'
project = short_root / 'policy_solution'
if project.exists():
    shutil.rmtree(project)
shutil.copytree(project_src, project)
python311 = Path(r'C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe')
venv = project / '.venv'
subprocess.run([str(python311), '-m', 'venv', str(venv)], check=True)
py = venv / 'Scripts' / 'python.exe'

for cmd in [
    [str(py), '-m', 'pip', 'install', '--upgrade', 'pip', 'setuptools', 'wheel'],
    [str(py), '-m', 'pip', 'install', '-e', '.[dev]'],
]:
    r = subprocess.run(cmd, cwd=str(project), text=True, capture_output=True)
    out = (r.stdout or '') + (r.stderr or '')
    print('CMD:', ' '.join(cmd))
    print(out[:4000])
    if r.returncode != 0:
        raise SystemExit(r.returncode)

# test suite
for name, args in [
    ('tests', [str(py), '-m', 'pytest', 'tests/', '-v']),
    ('routing_offline', [str(py), '-m', 'pytest', 'tests/test_us04_routing.py', '-v']),
]:
    r = subprocess.run(args, cwd=str(project), text=True, capture_output=True)
    out = (r.stdout or '') + (r.stderr or '')
    (out_root / f'{name}.txt').write_text(out, encoding='utf-8')
    print(f'--- {name} rc={r.returncode} ---')
    print(out[:3000])

# mypy & ruff
for name, args in [
    ('mypy', [str(py), '-m', 'mypy', 'policy_extractor']),
    ('ruff', [str(py), '-m', 'ruff', 'check', 'policy_extractor', 'tests']),
]:
    r = subprocess.run(args, cwd=str(project), text=True, capture_output=True)
    out = (r.stdout or '') + (r.stderr or '')
    (out_root / f'{name}.txt').write_text(out, encoding='utf-8')
    print(f'--- {name} rc={r.returncode} ---')
    print(out[:2000])

calib_code = '''from policy_extractor.routing import CalibrationLabel, calibration_report
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
'''
(project / 'calib.py').write_text(calib_code, encoding='utf-8')
shutil.copy2(project / 'calib.py', out_root / 'calib.py')
calib = subprocess.run([str(py), 'calib.py'], cwd=str(project), text=True, capture_output=True)
(out_root / 'calibration.txt').write_text((calib.stdout or '') + (calib.stderr or ''), encoding='utf-8')
print('--- calibration rc=', calib.returncode)
print((calib.stdout or '') + (calib.stderr or ''))

# perturbation: test retry null-field
retry_test = subprocess.run([str(py), '-m', 'pytest', 'tests/test_us01_retry.py', '-v'], cwd=str(project), text=True, capture_output=True)
(out_root / 'perturb_retry_tests.txt').write_text((retry_test.stdout or '') + (retry_test.stderr or ''), encoding='utf-8')
print('--- retry rc=', retry_test.returncode)
print((retry_test.stdout or '')[:2000])

# copy calib to perturbed version and adjust more correct auto points to show aggregate improves
perturbed = '''from policy_extractor.routing import CalibrationLabel, calibration_report
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
'''
(project / 'calib_perturbed.py').write_text(perturbed, encoding='utf-8')
calibp = subprocess.run([str(py), 'calib_perturbed.py'], cwd=str(project), text=True, capture_output=True)
(out_root / 'calibration_perturbed.txt').write_text((calibp.stdout or '') + (calibp.stderr or ''), encoding='utf-8')
print('--- perturbed rc=', calibp.returncode)
print((calibp.stdout or '')[:2000])
