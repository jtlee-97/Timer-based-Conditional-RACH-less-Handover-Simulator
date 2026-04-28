function run_all_revision()
%RUN_ALL_REVISION One-click revision experiment runner.

clearvars;
clc;
addpath(genpath('functions'));

cfg = revision_config();
results = run_revision_experiments(cfg);

disp('=== Revision experiment summary (Tstay error, ms) ===');
disp(results.summary);

disp('=== Clock drift sensitivity ===');
disp(results.clock);

disp(['Outputs saved to: ', cfg.output_dir]);
end
