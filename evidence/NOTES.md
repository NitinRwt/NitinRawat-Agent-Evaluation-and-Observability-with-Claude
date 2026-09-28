# Run notes

## Environment
- OS: Microsoft Windows NT 10.0.26200.0 (Windows 11 Home Single Language); PowerShell 5.1.26100.9444
- Python used for all venvs: **Python 3.11.9** (`C:\Users\soura\AppData\Local\Programs\Python\Python311\python.exe`)
  - An earlier attempt recorded `Python 3.9.13`, the same version as the workspace-root `.venv` (its `pyvenv.cfg` says `version = 3.9.13`). That interpreter is below the 3.11 minimum and was not used.
- Date run: 2026-09-28
- Evidence layout follows `Project-Evaluation and Observability Project/README.md` (e.g. `02-mortgage-extraction/`, `static-checks.txt`), as COPILOT_TASK.md instructs when the README defines one.

## API key
- `ANTHROPIC_API_KEY` set: **yes** (a Vocareum `voc-…` key, set only in the process environment and never written to any file).
- `ANTHROPIC_BASE_URL=https://claude.vocareum.com` (the Udacity/Vocareum proxy; the code's `anthropic.Anthropic()` reads both env vars, so no code change).
- **Path used: LIVE API** for System 1 (`pipeline_run.txt`, `routing_decisions.json`, `perturb_blank_field.txt`, `baseline_extract.txt`) and the System 2 perturbation (`run_sum_matched_live.txt`, `--mode record`). The offline routing tests were also captured (`routing_offline.txt`). System 2's main runs use `--mode replay` and System 3 uses `--offline`, as the runbook specifies.

## Problems hit and fixes
1. **Windows MAX_PATH broke the project-local venv.** `pip install -e ".[dev]"` into `<policy solution>\.venv` failed with
   `OSError: [Errno 2] No such file or directory: ...\anthropic\types\beta\prompt_caching\prompt_caching_beta_cache_control_ephemeral_param.py`
   and pip's hint about Windows Long Path support (`install-policy-FAILED-longpath-earlier-attempt.txt`). The half-installed package then failed at import with
   `ModuleNotFoundError: No module named 'anthropic.types.usage'`.
   **Fix:** created venvs at short paths `C:\ev\policy`, `C:\ev\mortgage`, `C:\ev\supply` and ran `pip install -e ".[dev]"` from each project folder. All three succeeded (`install-policy.txt`, `install-mortgage.txt`, `install-supply.txt`, each ending `[exit code: 0]`). Commands used `C:\ev\<name>\Scripts\<tool>` instead of `.venv\Scripts\<tool>`.
2. **PowerShell 5.1 has no `Tee-Object -Encoding`**, and plain `Tee-Object` writes UTF-16. All captures were written with `Out-File -Encoding utf8` via `run_evidence.ps1` (workspace root), with `PYTHONUTF8=1`. Each capture ends with an `[exit code: N]` line added by the script.
3. **Live policy tests are intermittent on the proxy.** In `tests.txt`, `test_live_extracts_well_formed_policy` and `test_live_dry_run_sample_against_real_api` failed with
   `Error code: 400 ... Model 'claude-haiku-4-5' is not available for your organization`. The same `test_live_extracts_well_formed_policy` **passed** minutes later in `perturb_retry_tests.txt`, and a rerun of the live tests (`tests_live_rerun.txt`) failed the same two again while `test_live_reviewer_returns_per_field_judgement` passed. The CLI runs using the same model all returned `HTTP/1.1 200 OK`. Treated as a proxy/model-access limitation, not a code defect; all non-live tests pass.
4. **`policy-extractor extract` needs `--policy-id`** (required argument in `__main__.py`); COPILOT_TASK.md omits it. Added `--policy-id POL-2025-001`.
5. **`mortgage-extract` exits 1 on a discrepancy by design** (`__main__.py:74`: `return 0 if report.consistent else 1`), so the `[exit code: 1]` in `run_sum_mismatch.txt` is the expected flag, not a failure.
6. **Supply-chain first run** printed `Warning: You are sending unauthenticated requests to the HF Hub` while downloading the embedding model. It is harmless and completed.

## Files added outside evidence/
- `Build a Validated, Routed ...\04-hitl-routing\solution\calib.py`, `calib_perturbed.py`
- `Build a Resilient Mortgage ...\04-validate-mathematical-consistency\solution\fixtures\documents\income_sum_matched.txt` (new fixture; originals untouched), plus two cache files that `--mode record` wrote to `fixtures\recorded_responses\` (`b267b90f1d56f8cf.json`, `dda94cefe3336c7a.json`; classify and extract passes)
- `run_evidence.ps1` (workspace root)
- Venvs at `C:\ev\`
