# Timer-based-Conditional-RACH-less-Handover-Simulator

MATLAB-based simulator for timer-synchronized CHO / RACH-less HO studies in LEO-like moving-beam scenarios.

## What this revision adds

This revision adds a **footprint-aware timer anchor** for TS-CHO-RAL:

- Baseline predictors kept:
  - Circular (`model='circle'`)
  - Hexagonal (`model='hex'`)
- New predictor:
  - Elliptical (`model='ellipse'`)

Core predictor equation:

\[
(r_0 + v\tau)^T Q (r_0 + v\tau) = 1,
\quad
Q = R(\theta)\,\mathrm{diag}(1/A^2, 1/B^2)\,R(\theta)^T
\]

Quadratic coefficients:

\[
a=v^TQv,\; b=2r_0^TQv,\; c=r_0^TQr_0-1
\]

Timer uses the smallest positive real root.

## Normalized elliptical distance

Distance-domain mode uses:

\[
d_{ell} = \sqrt{(p-c)^TQ(p-c)}
\]

- Boundary: `dEll = 1`
- Squared value is returned separately as `dEll2` in `normalized_ellipse_distance.m`.

## How to run original simulator

Use existing scripts as before (for example):

```matlab
system_start
```

No legacy function signatures were removed.

## How to run revision experiments (one-click)

```matlab
run_all_revision
```

This runs:
1. Circular / hex / elliptical residence-time predictors
2. Dense-sampled reference exit-time generation
3. Tstay prediction-error CDF + summary
4. Clock-drift sensitivity
5. HO/resource proxy metrics by predictor

## Main revision files

- `revision_config.m` : revision config (seed, drift set, model options, weights, output dir)
- `run_all_revision.m` : one-click runner
- `run_revision_experiments.m` : full pipeline
- `test_revision_geometry.m` : sanity tests

### New helper functions (functions/)

- `compute_time_window.m` (updated with `circle/hex/ellipse` modes)
- `make_ellipse_Q.m`
- `normalized_ellipse_distance.m`
- `fit_ellipse_from_points.m`
- `build_footprint_model.m`
- `compute_reference_exit_time.m`
- `rank_candidates_tscho.m`
- `GET_DIS_ML.m` (updated, backward compatible)

## Output files

Generated under `output/revision/`:

CSV:
- `tstay_error_cdf.csv`
- `tstay_error_summary.csv`
- `clock_drift_sensitivity.csv`
- `ho_metrics_by_predictor.csv`
- `config_used.txt`

Figures:
- `fig_tstay_error_cdf.png` (+ `.fig`)
- `fig_clock_drift_sensitivity.png` (+ `.fig`)
- `fig_ho_metrics_by_predictor.png` (+ `.fig`)

## Notes on candidate prioritization/fallback

`rank_candidates_tscho.m` ranks candidates using normalized RSRP, predicted residence-time, and execution timing consistency. If top-ranked target is not in prepared set, `candidate_miss` is flagged and fallback impact is logged in output metrics.

## Troubleshooting

- If `savefig` is unsupported (older MATLAB), PNG export still works.
- If Statistics Toolbox is unavailable (`ecdf`), replace CDF plotting with manual empirical CDF implementation.
- Ensure `addpath(genpath('functions'))` is executed when running scripts manually.

## MATLAB assumptions

- Tested for MATLAB R2020a+ syntax style.
- Scripts avoid hard-coded absolute paths and auto-create output directories.
