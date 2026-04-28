# Timer-based-Conditional-RACH-less-Handover-Simulator

LEO moving-beam HO simulator for CHO/CHO-RAL/TS-CHO-RAL studies.

## Quick start

### Original full simulator
```matlab
system_start
```

### System-level revision (paper-use candidate)
```matlab
run_system_revision
```

### Geometry equation validation only (debug)
```matlab
run_geometry_debug
```

`run_all_revision` is now an alias to `run_geometry_debug` and prints a warning.

---

## Important separation

- `output/system_revision/*`:
  - generated from the **original system pipeline** (`system_process`, original HO/RB/MIT/SINR accounting)
  - candidate for paper tables/figures **only if accounting scale sanity is met**.
- `output/geometry_debug/*`:
  - equation/geometry validation only
  - **not paper-level HO/RB/MIT results**.

A warning is printed when results are not on expected original accounting scale:

> `WARNING: Results are not connected to original system-level RB/MIT accounting.`

---

## Ellipse footprint-aware timer model

Residence-time equation:

\[
(r_0 + v\tau)^T Q (r_0 + v\tau)=1,
\quad Q=R(\theta)\,\mathrm{diag}(1/A^2,1/B^2)\,R(\theta)^T
\]

with
\[
a=v^TQv,\; b=2r_0^TQv,\; c=r_0^TQr_0-1
\]

and smallest positive real root used as exit-time predictor.

`compute_time_window` supports:
- `footprint.model='circle'`
- `footprint.model='hex'`
- `footprint.model='ellipse'`

Backward compatibility is preserved.

---

## Normalized elliptical distance

`normalized_ellipse_distance(p,c,A,B,theta)` returns:
- `dEll2 = (p-c)'Q(p-c)`
- `dEll = sqrt(dEll2)`

Boundary is `dEll = 1`.

`GET_DIS_ML` keeps legacy 4-argument Euclidean distance and supports optional ellipse mode.

---

## System pipeline map

See `SYSTEM_PIPELINE.md` for:
- `system_start -> system_process -> MTD_*`
- timer anchor insertion point
- RB/MIT/UHO/SINR accounting path

---

## Main outputs

### `output/system_revision/`
- `ho_metrics_by_predictor.csv`
- `clock_drift_sensitivity.csv`
- `fig_ho_metrics_by_predictor.png`
- `fig_clock_drift_sensitivity.png`
- `config_used.txt`

### `output/geometry_debug/`
- `tstay_error_cdf.csv`
- `tstay_error_summary.csv`
- `fig_tstay_error_cdf.png`
- `debug_samples.csv`

---

## Notes

- Clock drift is injected at the **actual execution-timer decision point** for A3T1-CHO-RAL path.
- A3 instability is still governed by standard A3/L3 filtering and TTT controls; timer predictor is not claimed as a replacement for A3 stabilization.
