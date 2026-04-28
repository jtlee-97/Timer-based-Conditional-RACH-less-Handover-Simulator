function out = run_system_revision()
%RUN_SYSTEM_REVISION Full-system revision runner using original pipeline/accounting.

clearvars -except out;
clc;
addpath(genpath('functions'));

% baseline scenario params from original pipeline
UE_TEST_SINGLE = true;
UE_TEST_X = 0.5 * 23120;
run('system_parameter.m');

predictors = {'circle','hex','ellipse'};
drift_ms_set = [-10 -5 -2 -1 0 1 2 5 10];
outDir = fullfile('output','system_revision');
if ~exist(outDir,'dir'), mkdir(outDir); end

% Strategy fixed to A3T1-CHO-RAL original mode (option=9)
strategy_mode = 9;
Offset = 1;
TTT = 0;
choOverride = struct('RACHLESS_GRANT_MODE','dynamic', 'DYN_GRANT_FAIL_ENABLE',false, ...
                     'DYN_GRANT_FAIL_PROB',0, 'DYN_GRANT_PREP_SEND',false);

metricsRows = [];
clockRows = [];

for p = 1:numel(predictors)
    timerPredictor = predictors{p}; %#ok<NASGU>
    footprintModelMode = 'ellipse_elevation'; %#ok<NASGU>
    footprintA = cellRadius; %#ok<NASGU>
    footprintB = cellRadius; %#ok<NASGU>
    footprintTheta = 0; %#ok<NASGU>
    footprintMaxTe = 60; %#ok<NASGU>
    footprintElevDeg = 35; %#ok<NASGU>
    deltaOffMs = 0; %#ok<NASGU>
    clockDriftMs = 0; %#ok<NASGU>

    [~, episode_results, final_results] = system_process(UE_x(1), UE_y, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, strategy_mode, Offset, TTT, choOverride);

    m = aggregate_original_metrics(episode_results, final_results);
    metricsRows = [metricsRows; {string(timerPredictor), m.ho_success_rate, m.wasted_ho_ratio, m.rb_per_ho, m.mit_ms, m.dl_sinr_db, m.candidate_miss_ratio}]; %#ok<AGROW>

    for d = 1:numel(drift_ms_set)
        clockDriftMs = drift_ms_set(d); %#ok<NASGU>
        [~, episode_results_d, final_results_d] = system_process(UE_x(1), UE_y, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, strategy_mode, Offset, TTT, choOverride);
        md = aggregate_original_metrics(episode_results_d, final_results_d);
        clockRows = [clockRows; {string(timerPredictor), drift_ms_set(d), md.wasted_ho_ratio, md.ho_success_rate, md.rb_per_ho, md.mit_ms, md.dl_sinr_db, md.candidate_miss_ratio}]; %#ok<AGROW>
    end
end

hoTbl = cell2table(metricsRows, 'VariableNames', {'predictor','ho_success_rate','wasted_ho_ratio','rb_per_ho','mit_ms','dl_sinr_db','candidate_miss_ratio'});
clkTbl = cell2table(clockRows, 'VariableNames', {'predictor','clock_drift_ms','wasted_ho_ratio','ho_success_rate','rb_per_ho','mit_ms','dl_sinr_db','candidate_miss_ratio'});

writetable(hoTbl, fullfile(outDir,'ho_metrics_by_predictor.csv'));
writetable(clkTbl, fullfile(outDir,'clock_drift_sensitivity.csv'));

% figure 1: by predictor
h=figure('Visible','off');
vals=[hoTbl.rb_per_ho, hoTbl.mit_ms, hoTbl.wasted_ho_ratio];
bar(vals); grid on;
set(gca,'XTickLabel',cellstr(hoTbl.predictor));
legend({'RB/HO','MIT (ms)','Wasted-HO'},'Location','bestoutside');
title('System revision metrics by predictor (original accounting)');
saveas(h, fullfile(outDir,'fig_ho_metrics_by_predictor.png')); close(h);

% figure 2: clock drift sensitivity (ellipse)
sel = strcmp(clkTbl.predictor,'ellipse');
h=figure('Visible','off');
plot(clkTbl.clock_drift_ms(sel), clkTbl.wasted_ho_ratio(sel), '-o','LineWidth',1.5); hold on;
plot(clkTbl.clock_drift_ms(sel), clkTbl.mit_ms(sel), '-s','LineWidth',1.5);
plot(clkTbl.clock_drift_ms(sel), clkTbl.rb_per_ho(sel), '-^','LineWidth',1.5);
legend({'Wasted-HO','MIT(ms)','RB/HO'},'Location','best');
xlabel('Clock drift [ms]'); ylabel('Metric'); grid on;
title('Clock drift sensitivity (original pipeline, ellipse predictor)');
saveas(h, fullfile(outDir,'fig_clock_drift_sensitivity.png')); close(h);

write_config(outDir, predictors, drift_ms_set, Offset, TTT);

% paper-scale warning
if ~(any(hoTbl.rb_per_ho > 9 & hoTbl.rb_per_ho < 25) && any(hoTbl.mit_ms > 10 & hoTbl.mit_ms < 60))
    warning('WARNING: Results are not connected to original system-level RB/MIT accounting.');
end

out = struct('ho',hoTbl,'clock',clkTbl);
end

function m = aggregate_original_metrics(episode_results, final_results)
    er = episode_results(1,:);
    ho = [er.HO];
    uho = [er.UHO];
    rb = [er.RBs];
    mit_events = [er.MIT_HO_EVENTS];
    mit_sum = [er.MIT_TOTAL_SUM];
    cand_miss = [er.CAND_MISS_COUNT];

    total_ho = sum(ho);
    m.ho_success_rate = total_ho / max(1, total_ho + sum(uho));
    m.wasted_ho_ratio = sum(uho) / max(1, total_ho);
    m.rb_per_ho = sum(rb) / max(1, total_ho);
    m.mit_ms = 1e3 * sum(mit_sum) / max(1, sum(mit_events));
    m.dl_sinr_db = final_results(1).final_avg_SINR;
    m.candidate_miss_ratio = sum(cand_miss) / max(1, total_ho);
end

function write_config(outDir, predictors, drift_ms_set, Offset, TTT)
    fid=fopen(fullfile(outDir,'config_used.txt'),'w');
    fprintf(fid,'timerPredictors: %s\n', strjoin(predictors, ', '));
    fprintf(fid,'drift_ms_set: %s\n', mat2str(drift_ms_set));
    fprintf(fid,'footprint mode in system_revision: ellipse_elevation\n');
    fprintf(fid,'OffsetA3(dB): %g\n', Offset);
    fprintf(fid,'TTT(ms): %d\n', TTT);
    if evalin('caller','exist(''k_rsrp'',''var'')')
        fprintf(fid,'L3_k_rsrp: %g\n', evalin('caller','k_rsrp'));
    else
        fprintf(fid,'L3_k_rsrp: n/a\n');
    end
    fprintf(fid,'A3 instability is controlled by L3 filtering/Offset/TTT, not solved by timer predictor.\n');
    fclose(fid);
end
