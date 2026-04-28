clear; clc; close all;

%% ===== User options =====
FIXED_N_SAMPLES = 5000;        % [] 이면 공통 최소 샘플 수 사용
HO_RATE_UNIT = 'per_min';      % 'per_min' or 'per_sec'
SIM_TIME_SEC_OVERRIDE = [];    % 필요 시 직접 지정
DEFAULT_SAMPLE_TIME_SEC = 0.2;

%% ===== Result directory =====
scriptDir = fileparts(mfilename('fullpath'));
resultsDir = fullfile(scriptDir, 'MasterResults');
if ~exist(resultsDir, 'dir')
    resultsDir = scriptDir;
end
fprintf('resultsDir = %s\n', resultsDir);

%% ===== Strategy order =====
targetStrategies = { ...
    'Strategy CHO-CFRA [A3=0dB,TTT=0ms]', ...
    'Strategy CHO-RAL [A3=0dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL [A3=0dB,TTT=0ms]', ...
    'Strategy CHO-CFRA [A3=1dB,TTT=0ms]', ...
    'Strategy CHO-RAL [A3=1dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL [A3=1dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL(R-2km) [A3=1dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL(R-1km) [A3=1dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL(R+1km) [A3=1dB,TTT=0ms]', ...
    'Strategy A3T1-CHO-RAL(R+2km) [A3=1dB,TTT=0ms]'};

%% ===== Load candidate MAT files =====
files = struct([]);
labels = {};

allMat = dir(fullfile(resultsDir, '*_MASTER_RESULTS_*.mat'));
fprintf('Found %d MAT files.\n', numel(allMat));
if ~isempty(allMat)
    disp({allMat.name}');
end

strategyCandidates = cell(1, numel(targetStrategies));

for k = 1:numel(targetStrategies)
    strategyToken = targetStrategies{k};
    hit = false(size(allMat));

    for j = 1:numel(allMat)
        hit(j) = match_strategy_token(allMat(j).name, strategyToken);
    end

    f = allMat(hit);
    fprintf('[%02d] %s --> %d files matched\n', k, strategyToken, numel(f));

    if isempty(f)
        strategyCandidates{k} = struct([]);
        continue;
    end

    for j = 1:numel(f)
        p = fullfile(resultsDir, f(j).name);
        tmp = load(p, 'MASTER_HO');
        if isfield(tmp, 'MASTER_HO')
            f(j).nSamples = numel(tmp.MASTER_HO);
        else
            f(j).nSamples = 0;
        end
    end
    strategyCandidates{k} = f;
end

%% ===== Fairness-matched file set =====
commonN = [];
allReady = true;
for k = 1:numel(targetStrategies)
    cand = strategyCandidates{k};
    if isempty(cand)
        allReady = false;
        break;
    end
    nset = unique([cand.nSamples]);
    if isempty(commonN)
        commonN = nset;
    else
        commonN = intersect(commonN, nset);
    end
end

usedFairSet = false;
if allReady && ~isempty(commonN)
    bestScore = -inf;
    bestFiles = struct([]);
    bestN = commonN(1);

    for n = commonN(:)'
        curFiles = struct([]);
        minDate = inf;
        validPack = true;

        for k = 1:numel(targetStrategies)
            cand = strategyCandidates{k};
            candN = cand([cand.nSamples] == n);
            if isempty(candN)
                validPack = false;
                break;
            end

            [~, ix] = max([candN.datenum]);
            pick = candN(ix);

            if isempty(curFiles)
                curFiles = pick;
            else
                curFiles(end+1) = pick; %#ok<SAGROW>
            end
            minDate = min(minDate, pick.datenum);
        end

        if validPack && minDate > bestScore
            bestScore = minDate;
            bestFiles = curFiles;
            bestN = n;
        end
    end

    if numel(bestFiles) == numel(targetStrategies)
        files = bestFiles;
        labels = targetStrategies;
        fprintf('Using fairness-matched set: common N_samples=%d across all target strategies.\n', bestN);
        usedFairSet = true;
    end
end

%% ===== Fallback: latest file per strategy =====
if ~usedFairSet
    for k = 1:numel(targetStrategies)
        cand = strategyCandidates{k};
        if ~isempty(cand)
            [~, ix] = max([cand.datenum]);
            if isempty(files)
                files = cand(ix);
            else
                files(end+1) = cand(ix); %#ok<SAGROW>
            end
            labels{end+1} = targetStrategies{k}; %#ok<SAGROW>
        end
    end
    warning('Could not build fairness-matched common N set. Fallback to latest-per-strategy files.');
end

%% ===== Check missing strategies =====
if numel(files) < numel(targetStrategies)
    fprintf('\n===== Missing strategy check =====\n');
    for k = 1:numel(targetStrategies)
        cand = strategyCandidates{k};
        if isempty(cand)
            fprintf('MISSING: %s\n', targetStrategies{k});
        end
    end

    requestedList = strjoin(targetStrategies, ' / ');
    error(['비교용 파일이 부족합니다. 요청한 %d개 전략(%s) 결과 MAT를 확인하세요.\n' ...
           '특히 MasterResults 폴더 경로와 저장 파일명을 다시 확인하세요.'], ...
           numel(targetStrategies), requestedList);
end

%% ===== Load full MAT contents =====
nFile = numel(files);
data = cell(1, nFile);

for k = 1:nFile
    data{k} = load(fullfile(resultsDir, files(k).name));
end

availSamples = zeros(1, nFile);
for k = 1:nFile
    availSamples(k) = available_samples_for_mat(data{k});
end

if isempty(FIXED_N_SAMPLES)
    nEval = min(availSamples);
    fprintf('Using auto common N_samples=%d for all target strategies.\n', nEval);
else
    nEval = round(FIXED_N_SAMPLES);
    if nEval <= 0
        error('FIXED_N_SAMPLES must be a positive integer.');
    end
    if any(availSamples < nEval)
        error('FIXED_N_SAMPLES=%d exceeds available samples in at least one MAT (available: %s).', ...
            nEval, mat2str(availSamples));
    end
    fprintf('Using configured fixed N_samples=%d for all target strategies.\n', nEval);
end

%% ===== Metric containers =====
mMIT               = NaN(1, nFile);
mRBs               = NaN(1, nFile);
mRBsPerHO          = NaN(1, nFile);
mHO                = NaN(1, nFile);
mHORate            = NaN(1, nFile);
mDynTx             = NaN(1, nFile);
mRachRB            = NaN(1, nFile);
mUHOCount          = NaN(1, nFile);
mUHOProb           = NaN(1, nFile);
mRLFProb           = NaN(1, nFile);
mShortToSProb      = NaN(1, nFile);
mHOPPProb          = NaN(1, nFile);
mEssentialHORate   = NaN(1, nFile);
mUHOPureRate       = NaN(1, nFile);
mHOPPRate          = NaN(1, nFile);
mTotalHORateBreakdown = NaN(1, nFile);
avgToS             = NaN(1, nFile);
avgSINR            = NaN(1, nFile);

%% ===== Metric extraction =====
for k = 1:nFile
    d = data{k};
    simTimeSec = infer_sim_time_sec(d, SIM_TIME_SEC_OVERRIDE, DEFAULT_SAMPLE_TIME_SEC, resultsDir);

    switch lower(strtrim(HO_RATE_UNIT))
        case 'per_min'
            hoRateScale = 60;
        case 'per_sec'
            hoRateScale = 1;
        otherwise
            error('HO_RATE_UNIT must be ''per_min'' or ''per_sec''.');
    end

    mit_total_vec = get_field_vec_n(d, 'MASTER_MIT_TOTAL', nEval);
    rb_vec        = get_field_vec_n(d, 'MASTER_RBs', nEval);
    ho_vec        = get_field_vec_n(d, 'MASTER_HO', nEval);
    dyn_tx_vec    = get_field_vec_n(d, 'MASTER_DYN_GRANT_TX_COUNT', nEval);
    rach_rb_vec   = get_field_vec_n(d, 'MASTER_RACH_RB_EQ', nEval);
    uho_vec       = get_field_vec_n(d, 'MASTER_UHO', nEval);
    hopp_vec      = get_field_vec_n(d, 'MASTER_HOPP', nEval);
    rlf_vec       = get_field_vec_n(d, 'MASTER_RLF', nEval);
    sinr_vec      = get_field_vec_n(d, 'MASTER_SINR', nEval);

    if ~isempty(mit_total_vec), mMIT(k) = mean(mit_total_vec) * 1e3; end
    if ~isempty(rb_vec),        mRBs(k) = mean(rb_vec);             end
    if ~isempty(dyn_tx_vec),    mDynTx(k) = mean(dyn_tx_vec);       end
    if ~isempty(rach_rb_vec),   mRachRB(k) = mean(rach_rb_vec);     end
    if ~isempty(rlf_vec),       mRLFProb(k) = mean(rlf_vec); else, mRLFProb(k) = 0; end
    if ~isempty(sinr_vec),      avgSINR(k) = mean(sinr_vec);        end

    if ~isempty(ho_vec)
        mHO(k) = mean(ho_vec);
        totalHO = sum(ho_vec);

        if ~isnan(simTimeSec) && simTimeSec > 0
            mHORate(k) = (mHO(k) / simTimeSec) * hoRateScale;
        end

        if totalHO > 0 && ~isempty(rb_vec)
            mRBsPerHO(k) = sum(rb_vec) / totalHO;
        end

        uho_sum  = sum(uho_vec);
        hopp_sum = sum(hopp_vec);

        if totalHO > 0
            mUHOProb(k)  = 100 * uho_sum  / totalHO;
            mHOPPProb(k) = 100 * hopp_sum / totalHO;
        else
            mUHOProb(k)  = 0;
            mHOPPProb(k) = 0;
        end

        if ~isempty(uho_vec)
            mUHOCount(k) = mean(uho_vec);
        else
            mUHOCount(k) = 0;
        end

        if ~isnan(simTimeSec) && simTimeSec > 0
            normFactor = hoRateScale / (numel(ho_vec) * simTimeSec);
            essential_cnt = max(0, totalHO - uho_sum);
            pure_uho_cnt  = max(0, uho_sum - hopp_sum);
            hopp_cnt      = max(0, hopp_sum);

            mEssentialHORate(k) = essential_cnt * normFactor;
            mUHOPureRate(k)     = pure_uho_cnt * normFactor;
            mHOPPRate(k)        = hopp_cnt * normFactor;
            mTotalHORateBreakdown(k) = mEssentialHORate(k) + mUHOPureRate(k) + mHOPPRate(k);
        end
    end

    if isfield(d, 'MASTER_ToS') && ~isempty(d.MASTER_ToS)
        tos_data = d.MASTER_ToS(:);
        avgToS(k) = mean(tos_data);
        short_tos_count = sum(tos_data < 1);
        if ~isempty(tos_data)
            mShortToSProb(k) = 100 * short_tos_count / numel(tos_data);
        else
            mShortToSProb(k) = 0;
        end
    else
        avgToS(k) = NaN;
        mShortToSProb(k) = 0;
    end
end

%% ===== Derived metrics =====
mWastedProb = mUHOProb;

%% ===== Plot subset indices =====
idxCmp00 = [1 2 3];
idxCmp10 = [4 5 6];
labelsCmp = {'CHO-CFRA', 'CHO-RAL', 'Proposed'};

idxA3T1_5 = [7 8 6 9 10];
labelsA3T1 = { ...
    '\Delta_{off}=-t_{2km}', ...
    '\Delta_{off}=-t_{1km}', ...
    '\Delta_{off}=0', ...
    '\Delta_{off}=t_{1km}', ...
    '\Delta_{off}=t_{2km}'};


%% =======================================================================
% Fig1: MIT + RBs/HO
%   - shared legend at top center
%   - (a), (b) placed close to each subplot
% ========================================================================
fig1 = figure('Name', 'Fig1_MIT_RBs_subplots', 'Color', 'w');
set(fig1, 'Units', 'inches', 'Position', [1.0 1.0 8.4 4.8]);

% subplot axes (약간 아래로 내려서 위쪽 legend 공간 확보)
ax1 = axes(fig1, 'Position', [0.09 0.23 0.36 0.65]);
[h1a, h1b] = plot_dualbar_metric(ax1, idxCmp00, labelsCmp, mMIT, mRBsPerHO, ...
    'Average MIT [ms]', 'Average RBs/HO');

ax2 = axes(fig1, 'Position', [0.55 0.23 0.36 0.65]);
plot_dualbar_metric(ax2, idxCmp10, labelsCmp, mMIT, mRBsPerHO, ...
    'Average MIT [ms]', 'Average RBs/HO');

% shared legend at top center
lgd1 = legend(ax1, [h1a, h1b], {'MIT (ms)', 'RBs/HO'});
set(lgd1, ...
    'Orientation', 'horizontal', ...
    'Box', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.39 0.90 0.22 0.04], ...   % ← 상단 중앙
    'FontSize', 15);

% (a), (b) close to subplot bottom
annotation(fig1, 'textbox', [0.24 0.14 0.06 0.03], ...
    'String', '(a)', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 15);

annotation(fig1, 'textbox', [0.70 0.14 0.06 0.03], ...
    'String', '(b)', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 15);

exportgraphics(fig1, fullfile(resultsDir, 'Fig1_MIT_RBs_subplots.png'), 'Resolution', 600);
savefig(fig1, fullfile(resultsDir, 'Fig1_MIT_RBs_subplots.fig'));

%% =======================================================================
% Fig3: HO Efficiency Breakdown
%   - shared legend at top center
%   - (a), (b) placed close to each subplot
%   - common y-scale for left/right subplots
% ========================================================================
fig3 = figure('Name', 'Fig3_HOEfficiency_subplots', 'Color', 'w');
set(fig3, 'Toolbar', 'none', 'Units', 'inches', 'Position', [1.0 1.0 8.6 5.0]);

ax3 = axes(fig3, 'Position', [0.08 0.23 0.38 0.65]);
ax4 = axes(fig3, 'Position', [0.54 0.23 0.38 0.65]);

% ===== 공통 y-limit 계산 =====
idxAllFig3 = [idxCmp00 idxCmp10];
validAllFig3 = mTotalHORateBreakdown(idxAllFig3);
validAllFig3 = validAllFig3(isfinite(validAllFig3));

if ~isempty(validAllFig3) && max(validAllFig3) > 0
    yMaxGlobalFig3 = max(validAllFig3) * 1.22;
else
    yMaxGlobalFig3 = 1;
end

[h31, h32, h34] = plot_hoeff_breakdown(ax3, idxCmp00, labelsCmp, ...
    mEssentialHORate, mUHOPureRate, mTotalHORateBreakdown, HO_RATE_UNIT);

plot_hoeff_breakdown(ax4, idxCmp10, labelsCmp, ...
    mEssentialHORate, mUHOPureRate, mTotalHORateBreakdown, HO_RATE_UNIT);

% ===== 좌우 subplot에 동일 y-scale 강제 적용 =====
ylim(ax3, [0 yMaxGlobalFig3]);
ylim(ax4, [0 yMaxGlobalFig3]);

% shared legend at top center
axLegend3 = axes(fig3, 'Position', [0 0 1 1], 'Visible', 'off');
lgd3 = legend(axLegend3, [h31 h32 h34], ...
    {'Essential HO (Valid)', 'Wasted HO (UHO)', 'Wasted ratio (%)'});

set(lgd3, ...
    'Orientation', 'horizontal', ...
    'Box', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.25 0.92 0.50 0.04], ...
    'FontSize', 15);

% (a), (b)
annotation(fig3, 'textbox', [0.24 0.13 0.06 0.03], ...
    'String', '(a)', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 15);

annotation(fig3, 'textbox', [0.70 0.13 0.06 0.03], ...
    'String', '(b)', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontWeight', 'bold', ...
    'FontSize', 15);

exportgraphics(fig3, fullfile(resultsDir, 'Fig3_HOEfficiency_subplots.png'), 'Resolution', 600);
savefig(fig3, fullfile(resultsDir, 'Fig3_HOEfficiency_subplots.fig'));

%% =======================================================================
% Fig5: A3T1 timer sensitivity (5 cases)
% ========================================================================
fig5 = figure('Name', 'Fig5_TimerSensitivity_A3T1_5cases', 'Color', 'w');
set(fig5, 'Toolbar', 'none', 'Units', 'inches', 'Position', [1.2 1.2 5.4 4.6]);

x = 1:numel(idxA3T1_5);

yyaxis left;
pWasteVar = plot(x, mWastedProb(idxA3T1_5), '-o', ...
    'LineWidth', 2.2, ...
    'MarkerSize', 7.5, ...
    'Color', [0.85 0.33 0.10], ...
    'MarkerFaceColor', [0.85 0.33 0.10]);
ylabel('Wasted HO ratio [%]');
ax5 = gca;
ax5.YAxis(1).Color = [0.85 0.33 0.10];

validWasteVar = mWastedProb(idxA3T1_5);
validWasteVar = validWasteVar(isfinite(validWasteVar));
safe_set_ylim_nonneg(ax5, validWasteVar, 1.30);

yoffW = safe_text_offset(validWasteVar, 0.05, 0.10);
for i = 1:numel(idxA3T1_5)
    yv = mWastedProb(idxA3T1_5(i));
    if isfinite(yv)
        text(i, yv + yoffW, sprintf('%.2f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 15, ...
            'FontWeight', 'bold', ...
            'Color', [0.55 0.18 0.05]);
    end
end

yyaxis right;
pSINR = plot(x, avgSINR(idxA3T1_5), '-s', ...
    'LineWidth', 2.2, ...
    'MarkerSize', 6.8, ...
    'Color', [0.12 0.38 0.80], ...
    'MarkerFaceColor', [0.12 0.38 0.80]);
ylabel('Average DL SINR [dB]');
ax5.YAxis(2).Color = [0.12 0.38 0.80];

validSINR = avgSINR(idxA3T1_5);
validSINR = validSINR(isfinite(validSINR));
safe_set_ylim_signed(ax5, validSINR, 0.20);

yoffS = safe_text_offset_range(validSINR, 0.06, 0.05);
for i = 1:numel(idxA3T1_5)
    yv = avgSINR(idxA3T1_5(i));
    if isfinite(yv)
        text(i, yv + yoffS, sprintf('%.2f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 15, ...
            'FontWeight', 'bold', ...
            'Color', [0.05 0.22 0.55]);
    end
end

grid on;
set(gca, 'XTick', x, 'XTickLabel', labelsA3T1, 'XTickLabelRotation', 12, 'FontSize', 13);
legend([pWasteVar, pSINR], ...
    {'Wasted HO ratio [%]', 'Average DL SINR [dB]'}, ...
    'Location', 'northeast', ...
    'Box', 'off', ...
    'FontSize', 15);


exportgraphics(fig5, fullfile(resultsDir, 'Fig5_TimerSensitivity_A3T1_5cases.png'), 'Resolution', 600);
savefig(fig5, fullfile(resultsDir, 'Fig5_TimerSensitivity_A3T1_5cases.fig'));

%% ===== Console summary =====
disp('================ Final Focused Figure Summary ================');
summaryTable = table(labels(:), mMIT(:), mRBsPerHO(:), mWastedProb(:), ...
    mShortToSProb(:), avgSINR(:), ...
    'VariableNames', {'Strategy','MIT_ms','RBs_per_HO','WastedHO_ratio_pct','ShortToS_pct','AvgDL_SINR_dB'});
disp(summaryTable);

disp('Generated figures:');
disp('  1) Fig1_MIT_RBs_subplots');
disp('  2) Fig3_HOEfficiency_subplots');
disp('  3) Fig5_TimerSensitivity_A3T1_5cases');

%% ===== Helper functions =====
function tf = match_strategy_token(fileName, strategyToken)
    tf = contains(fileName, strategyToken);
end

function n = available_samples_for_mat(d)
    if isfield(d, 'MASTER_HO') && ~isempty(d.MASTER_HO)
        n = numel(d.MASTER_HO);
    elseif isfield(d, 'MASTER_RBs') && ~isempty(d.MASTER_RBs)
        n = numel(d.MASTER_RBs);
    else
        n = 0;
    end
end

function v = get_field_vec_n(d, fieldName, nEval)
    if ~isfield(d, fieldName) || isempty(d.(fieldName))
        v = [];
        return;
    end
    vv = d.(fieldName);
    vv = vv(:);
    if isempty(vv)
        v = [];
        return;
    end
    takeN = min(nEval, numel(vv));
    v = vv(1:takeN);
end

function simTimeSec = infer_sim_time_sec(d, simTimeOverride, defaultSampleTimeSec, resultsDir)
    if ~isempty(simTimeOverride) && isscalar(simTimeOverride) && simTimeOverride > 0
        simTimeSec = simTimeOverride;
        return;
    end

    if isfield(d, 'TOTAL_TIME') && ~isempty(d.TOTAL_TIME) && isscalar(d.TOTAL_TIME) && d.TOTAL_TIME > 0
        simTimeSec = double(d.TOTAL_TIME);
        return;
    end

    if isfield(d, 'TIMEVECTOR') && ~isempty(d.TIMEVECTOR)
        tv = d.TIMEVECTOR(:);
        if numel(tv) >= 2
            simTimeSec = max(tv) - min(tv);
            if simTimeSec > 0
                return;
            end
        end
    end

    if isfield(d, 'MASTER_RAW_SINR') && ~isempty(d.MASTER_RAW_SINR)
        simTimeSec = size(d.MASTER_RAW_SINR, 1) * defaultSampleTimeSec;
        return;
    end

    if isfield(d, 'MASTER_RAW_RSRP') && ~isempty(d.MASTER_RAW_RSRP)
        simTimeSec = size(d.MASTER_RAW_RSRP, 1) * defaultSampleTimeSec;
        return;
    end

    simTimeSec = NaN;
    paramFile = fullfile(resultsDir, '..', 'system_parameter.m');
    if exist(paramFile, 'file') == 2
        try
            run(paramFile);
            if exist('TOTAL_TIME', 'var') && isscalar(TOTAL_TIME) && TOTAL_TIME > 0
                simTimeSec = double(TOTAL_TIME);
            end
        catch
            simTimeSec = NaN;
        end
    end
end

function [b1, b2] = plot_dualbar_metric(ax, idxSet, xLabels, leftDataAll, rightDataAll, leftYLabel, rightYLabel)
    x = 1:numel(idxSet);

    yyaxis(ax, 'left');
    b1 = bar(ax, x - 0.17, leftDataAll(idxSet), 0.34, ...
        'FaceColor', [0.86 0.33 0.31], ...
        'EdgeColor', [0.55 0.18 0.18], ...
        'FaceAlpha', 0.82);
    ylabel(ax, leftYLabel);
    ax.YAxis(1).Color = [0.55 0.18 0.18];

    validLeft = leftDataAll(idxSet);
    validLeft = validLeft(isfinite(validLeft));
    yyaxis(ax, 'left');
    safe_set_ylim_nonneg(ax, validLeft, 1.22);

    yoffLeft = safe_text_offset(validLeft, 0.02, 0.02);
    for ii = 1:numel(idxSet)
        yv = leftDataAll(idxSet(ii));
        if isfinite(yv)
            text(ax, x(ii)-0.17, yv + yoffLeft, sprintf('%.2f', yv), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 9.5, ...
                'FontWeight', 'bold', ...
                'Color', [0.45 0.10 0.10]);
        end
    end

    yyaxis(ax, 'right');
    b2 = bar(ax, x + 0.17, rightDataAll(idxSet), 0.34, ...
        'FaceColor', [0.22 0.48 0.84], ...
        'EdgeColor', [0.10 0.25 0.55], ...
        'FaceAlpha', 0.78);
    ylabel(ax, rightYLabel);
    ax.YAxis(2).Color = [0.10 0.25 0.55];

    validRight = rightDataAll(idxSet);
    validRight = validRight(isfinite(validRight));
    yyaxis(ax, 'right');
    safe_set_ylim_nonneg(ax, validRight, 1.25);

    yoffRight = safe_text_offset(validRight, 0.03, 0.03);
    for ii = 1:numel(idxSet)
        yv = rightDataAll(idxSet(ii));
        if isfinite(yv)
            text(ax, x(ii)+0.17, yv + yoffRight, sprintf('%.2f', yv), ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 9.5, ...
                'FontWeight', 'bold', ...
                'Color', [0.05 0.22 0.55]);
        end
    end

    grid(ax, 'on');
    set(ax, 'XTick', x, 'XTickLabel', xLabels, 'XTickLabelRotation', 8, 'FontSize', 10);
end

function safe_set_ylim_nonneg(ax, validVals, scale)
    if nargin < 3
        scale = 1.20;
    end
    validVals = validVals(isfinite(validVals));
    if isempty(validVals)
        ylim(ax, [0 1]);
        return;
    end
    ymax = max(validVals);
    if ~isfinite(ymax) || ymax <= 0
        ylim(ax, [0 1]);
    else
        ylim(ax, [0 ymax * scale]);
    end
end

function safe_set_ylim_signed(ax, validVals, marginRatio)
    if nargin < 3
        marginRatio = 0.20;
    end
    validVals = validVals(isfinite(validVals));
    if isempty(validVals)
        ylim(ax, [0 1]);
        return;
    end
    ymin = min(validVals);
    ymax = max(validVals);

    if ~isfinite(ymin) || ~isfinite(ymax)
        ylim(ax, [0 1]);
        return;
    end

    if abs(ymax - ymin) < 1e-9
        if ymax == 0
            ylim(ax, [-1 1]);
        else
            pad = max(abs(ymax)*0.2, 0.5);
            ylim(ax, [ymin-pad, ymax+pad]);
        end
    else
        pad = marginRatio * (ymax - ymin);
        ylim(ax, [ymin - pad, ymax + pad]);
    end
end

function yoff = safe_text_offset(validVals, ratio, fallback)
    validVals = validVals(isfinite(validVals));
    if isempty(validVals)
        yoff = fallback;
        return;
    end
    ymax = max(validVals);
    if ~isfinite(ymax) || ymax <= 0
        yoff = fallback;
    else
        yoff = ratio * ymax;
    end
end

function yoff = safe_text_offset_range(validVals, ratio, fallback)
    validVals = validVals(isfinite(validVals));
    if isempty(validVals)
        yoff = fallback;
        return;
    end
    r = max(validVals) - min(validVals);
    if ~isfinite(r) || r < 1e-9
        yoff = fallback;
    else
        yoff = ratio * r;
    end
end

function [h1, h2, h3] = plot_hoeff_breakdown(ax, idxSet, xLabels, ...
    mEssentialHORate, mUHOPureRate, mTotalHORateBreakdown, HO_RATE_UNIT)

    cla(ax, 'reset');
    hold(ax, 'on');
    grid(ax, 'on');

    x = 1:numel(idxSet);
    barW = 0.62;

    yEssential = mEssentialHORate(idxSet(:));
    yUHO       = mUHOPureRate(idxSet(:));

    cEssential = [0.2 0.6 0.2];
    cUHO       = [0.8 0.2 0.2];

    eEssential = [0.15 0.35 0.15];
    eUHO       = [0.45 0.10 0.10];

    for ii = 1:numel(x)
        left = x(ii) - barW/2;

        yE = yEssential(ii);
        yU = yUHO(ii);

        if ~isfinite(yE), yE = 0; end
        if ~isfinite(yU), yU = 0; end

        % Essential
        rectangle(ax, ...
            'Position', [left, 0, barW, max(0, yE)], ...
            'FaceColor', cEssential, ...
            'EdgeColor', eEssential, ...
            'LineWidth', 1.0);

        % UHO
        if yU > 0
            rectangle(ax, ...
                'Position', [left, max(0, yE), barW, yU], ...
                'FaceColor', cUHO, ...
                'EdgeColor', eUHO, ...
                'LineWidth', 1.0);
        end
    end

    set(ax, 'XTick', x, 'XTickLabel', xLabels, 'XTickLabelRotation', 8, 'FontSize', 10);
    xlim(ax, [0.4, numel(idxSet)+0.6]);

    switch lower(strtrim(HO_RATE_UNIT))
        case 'per_min'
            effLabel = 'Average HOs [#/UE/min.]';
        case 'per_sec'
            effLabel = 'Average HOs [#/UE/sec.]';
        otherwise
            effLabel = 'Average HOs';
    end
    ylabel(ax, effLabel);

    validTot = mTotalHORateBreakdown(idxSet);
    validTot = validTot(isfinite(validTot));

    if ~isempty(validTot) && max(validTot) > 0
        ymax = max(validTot) * 1.22;
        ylim(ax, [0, ymax]);
    else
        ylim(ax, [0, 1]);
    end

    % wasted ratio text
    for ii = 1:numel(idxSet)
        k = idxSet(ii);

        totalVal = mTotalHORateBreakdown(k);
        if ~isfinite(totalVal), continue; end

        wastedVal = mUHOPureRate(k);

        if totalVal > 0
            wastePct = (wastedVal / totalVal) * 100;
        else
            wastePct = 0;
        end

        offset = max(validTot) * 0.02;

        text(ax, ii, totalVal + offset, sprintf('%.2f%%', wastePct), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', [0.0 0.35 0.90]);
    end

    % legend handles
    h1 = plot(ax, nan, nan, 's', 'MarkerSize', 9, ...
        'MarkerFaceColor', cEssential, ...
        'MarkerEdgeColor', eEssential, ...
        'LineStyle', 'none');

    h2 = plot(ax, nan, nan, 's', 'MarkerSize', 9, ...
        'MarkerFaceColor', cUHO, ...
        'MarkerEdgeColor', eUHO, ...
        'LineStyle', 'none');

    % wasted ratio marker
    h3 = plot(ax, nan, nan, 's', ...
        'MarkerSize', 8, ...
        'MarkerFaceColor', [0.0 0.35 0.90], ...
        'MarkerEdgeColor', [0.0 0.35 0.90], ...
        'LineStyle', 'none');

    hold(ax, 'off');
end