"""Perturbed calibration: same 6 labels as calib.py, plus 20 extra correct auto/premium_amount
samples. Prediction: OVERALL brier improves (drops) while umbrella/exclusions stays acc=0.00."""
from policy_extractor.routing import CalibrationLabel, calibration_report
labels = [
    CalibrationLabel(policy_id="POL-1", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-2", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-3", policy_type="auto",     field="premium_amount", predicted_confidence=0.95, correct=True),
    CalibrationLabel(policy_id="POL-4", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-5", policy_type="umbrella", field="exclusions",     predicted_confidence=0.93, correct=False),
    CalibrationLabel(policy_id="POL-6", policy_type="home",     field="deductible",     predicted_confidence=0.90, correct=True),
]
# Perturbation: flood the easy cell with 20 more correct, confident auto samples.
labels += [
    CalibrationLabel(policy_id=f"POL-A{i:02d}", policy_type="auto", field="premium_amount", predicted_confidence=0.95, correct=True)
    for i in range(20)
]
report = calibration_report(labels)
for (ptype, fname), cell in sorted(report.cells.items()):
    print(f"{ptype:9} {fname:15} n={cell.samples} conf={cell.mean_predicted_confidence:.2f} "
          f"acc={cell.observed_accuracy:.2f} brier={cell.brier_score:.3f}")
print(f"OVERALL brier={report.overall_brier:.3f}")
