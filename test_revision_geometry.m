function test_revision_geometry()
%TEST_REVISION_GEOMETRY Sanity checks for revision geometry logic.

addpath(genpath('functions'));

UE = [100, 0];
C  = [0, 0];
R  = 200;
v_sat = [0, 10];
v_ue = [0, 0];

% 1) Circle mode still works
fpC = struct('model','circle');
[ThC, Tc, infoC] = compute_time_window(UE, C, R, v_sat, v_ue, false, false, fpC);
assert(isfinite(Tc) && Tc > 0);
assert(strcmp(infoC.model, 'circle'));

% 2) Ellipse with A=B equals circle
fpE = struct('model','ellipse','A',R,'B',R,'theta',0,'maxTe',inf);
[ThE, ~, ~] = compute_time_window(UE, C, R, v_sat, v_ue, false, false, fpE);
assert(abs(ThE - Tc) < 1e-6);

% 3) normalized_ellipse_distance returns 1 on boundary
[dEll, dEll2] = normalized_ellipse_distance([R;0], [0;0], R, R, 0);
assert(abs(dEll - 1) < 1e-9);
assert(abs(dEll2 - 1) < 1e-9);

% 4) smallest positive root selection
UE2 = [0, 0];
v_sat2 = [1, 0];
fpE2 = struct('model','ellipse','A',10,'B',5,'theta',0,'maxTe',inf);
[ThE2, ~, infoE2] = compute_time_window(UE2, C, 10, v_sat2, [0,0], false, false, fpE2);
assert(ThE2 > 0);
assert(abs(ThE2 - infoE2.ellipse.selected_root) < 1e-9);

% 5) outside UE => Te=0
UE_out = [300, 0];
[ThOut, ~, infoOut] = compute_time_window(UE_out, C, R, v_sat, v_ue, false, false, fpE);
assert(ThOut == 0);
assert(strcmp(infoOut.ellipse.status, 'outside'));

% 6) stationary UE => Te=inf or clamped maxTe
fpEs = struct('model','ellipse','A',R,'B',R,'theta',0,'maxTe',12);
[ThSt, ~, infoSt] = compute_time_window(UE, C, R, [0,0], [0,0], false, false, fpEs);
assert(ThSt == 12);
assert(strcmp(infoSt.ellipse.status, 'clamped') || strcmp(infoSt.ellipse.status, 'stationary'));

% 7) GET_DIS_ML old call still works
d = GET_DIS_ML([0 100], [0 0], 0, 0);
assert(numel(d) == 2 && abs(d(2)-100) < 1e-9);

disp('test_revision_geometry: all checks passed.');
end
