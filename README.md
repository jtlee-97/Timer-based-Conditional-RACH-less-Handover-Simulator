# Timer-based-Conditional-RACH-less-Handover-Simulator

## Elliptical footprint-aware timer (revision helper)

This repository now supports an elliptical residence-time predictor to replace the fixed circular anchor when needed for LEO projected footprints.

### 1) Time-window prediction (ellipse)

```matlab
footprint = struct('model','ellipse', 'A', A_s, 'B', B_s, 'theta', theta_s);
[Th, Tc, info] = compute_time_window(UE_xy, C_xy, R, v_sat_xy, v_ue_xy, true, false, footprint);
```

- `Th`: ellipse exit-time predictor (`Te`) in ellipse mode.
- `Tc`: legacy circular predictor for baseline comparison.
- `info.ellipse`: quadratic coefficients/discriminant and shape matrix `Q`.

### 2) Distance-domain mapping (normalized elliptical distance)

```matlab
ML_ell = GET_DIS_ML(BORE_X, BORE_Y, UE_X, UE_Y, A_vec, B_vec, theta_vec);
```

This computes
`d_ell = sqrt((p_UE-q_s)^T Q_s (p_UE-q_s))`,
so boundary crossing corresponds to `d_ell = 1`.

If only four arguments are passed, `GET_DIS_ML` keeps the legacy Euclidean behavior.
