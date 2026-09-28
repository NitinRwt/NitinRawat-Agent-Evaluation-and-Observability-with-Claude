# System 3 — Perturbation (supply chain, `--simulate-timeout`)

- **Change:** `supply-chain-investigate meridian --offline --simulate-timeout`. This makes the logistics reader raise a
  timeout partway through (`readers.py` `fail_after`, wired in `coordinator.py` via `simulate_logistics_timeout`).
- **Prediction:** the run completes and logistics-derived metrics move to Incomplete.
- **Captures:** `briefing_normal.txt`, `briefing_timeout.txt`, `briefing_diff.txt` (`Compare-Object`; `<=` = only in normal, `=>` = only in timeout).

## Which source failed

`briefing_timeout.txt`: `> Sources unavailable: logistics unavailable (timeout)`. The run still finished with `[exit code: 0]`.

## What moved into Incomplete

- `late_shipment_count` went from Well-Established `_[single source only]_` (`11.0 shipments — logistics (as of 2026-04-05)`)
  to Incomplete: `### late_shipment_count  _[missing source: timeout reading logistics]_`.
- `production_capacity_utilization` was already Incomplete in both runs (`missing source: no source reported this metric`).
  This is the contrast between *unreachable* (`timeout reading logistics`) and *nothing to report* (`no source reported this metric`).

## Did any Well-Established claim lose support?

Yes, two:

1. `average_lead_time_days` dropped from `_[corroborated across 2 sources]_` to `_[single source only]_`
   (only `12.0 days — supplier_audit (as of 2026-04-10)` remains). It stays in Well-Established with weaker support.
2. **`on_time_delivery_rate` stopped being contested.** In the normal run it is under Contested,
   `_[2 sources, conflicting]_  ⚠️ ESCALATE`, with `95.0 percent — supplier_audit (as of 2026-04-10)` against
   `78.0 percent — logistics (as of 2026-04-05)`. With logistics down it moves into **Well-Established** as
   `_[single source only]_` showing only `95.0 percent — supplier_audit`. Contested becomes `_none_` and the ESCALATE flag disappears.
   The more optimistic supplier-reported figure is now presented as established. Only the banner at the top of the briefing
   signals that the conflicting source is missing.

## Unchanged

`defect_rate_ppm` (`_[corroborated across 2 sources]_`, supplier_audit + internal_quality), `field_return_rate`,
`field_quality_concern`, `port_disruption` and `supplier_financial_distress` do not depend on logistics and don't appear in the diff.
