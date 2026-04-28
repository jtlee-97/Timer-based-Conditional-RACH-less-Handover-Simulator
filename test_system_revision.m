function test_system_revision()
%TEST_SYSTEM_REVISION Static sanity checks for system revision wiring.

assert(exist('run_system_revision.m','file')==2);
assert(exist('run_geometry_debug.m','file')==2);
assert(exist(fullfile('functions','compute_time_window.m'),'file')==2);
assert(exist(fullfile('functions','normalized_ellipse_distance.m'),'file')==2);
assert(exist(fullfile('functions','rank_candidates_tscho.m'),'file')==2);

txt = fileread('functions/MTD_A3T1_CHO_rachless.m');
assert(contains(txt, 'EXEC_TIME_THRESHOLD'));
assert(contains(txt, 'CLOCK_DRIFT_MS'));
assert(contains(txt, 'rank_candidates_tscho'));

disp('test_system_revision: static wiring checks passed.');
end
