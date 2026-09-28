# System 3 — Reflection (multi-source supply-chain synthesis)

> Sentences marked **[opinion]** are judgment, not evidence. Edit them as you see fit.

## 1. What the system guarantees

Every claim carries its source and date. Conflicting sources are shown side by side and escalated rather than merged into one number, and a source that fails is reported as unavailable while the run still finishes.

## 2. Evidence

- `tests.txt`: `34 passed, 2 warnings in 57.48s`. `static-checks.txt`: mypy `Success: no issues found in 8 source files`; ruff `All checks passed!`
- `briefing_normal.txt` has `## Well-Established`, `## Contested` and `## Incomplete`. Logistics is listed as a source (`11.0 shipments — logistics (as of 2026-04-05)`).
- Conflict, attributed and dated: `95.0 percent — supplier_audit (as of 2026-04-10)` against `78.0 percent — logistics (as of 2026-04-05)`, under `## Contested` with `escalation: high-impact metric is contested across sources`.
- `briefing_timeout.txt`: `> Sources unavailable: logistics unavailable (timeout)` and `late_shipment_count  _[missing source: timeout reading logistics]_`, `[exit code: 0]`.

## 3. What the perturbation showed

Graceful degradation works in the narrow sense: the run finished, and the logistics-only metric was marked Incomplete with the cause (`timeout reading logistics`), separate from `no source reported this metric`. But `briefing_diff.txt` shows the on-time-delivery conflict disappearing. With logistics gone, `on_time_delivery_rate` appears under Well-Established as `_[single source only]_` at 95.0 percent, and Contested reads `_none_`.

## 4. Where it could still fail

- A source outage can quietly turn a contested metric into an apparently settled one. A metric that was contested in the last complete run should stay flagged when one of its sources fails. **[opinion]**
- Single-source items appear under the "Well-Established" heading (e.g. `supplier_financial_distress  _[single source only]_`). The heading overstates certainty for a reader who skims. **[opinion]**
- Dates keep a time difference from reading as a contradiction (2026-04-10 vs 2026-04-05), but nothing stops stale data from being preferred when the newer source goes dark. **[opinion]**
