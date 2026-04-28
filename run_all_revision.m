function run_all_revision()
%RUN_ALL_REVISION Legacy alias for geometry debug runner.
warning('Proxy/debug metrics are for equation validation only and must not be used as paper results.');
results = run_geometry_debug(); %#ok<NASGU>
end
