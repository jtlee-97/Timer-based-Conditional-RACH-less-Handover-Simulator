%% plot_two_latest_results_simple.m
% 8세트 비교: BHO-CFRA / CHO-CFRA / CHO-RAL / A3T1-CHO-RAL(base) / A3T1-CHO-RAL(R-2km) / A3T1-CHO-RAL(R-1km) / A3T1-CHO-RAL(R+1km) / A3T1-CHO-RAL(R+2km)
% 지표:
%  - Average MIT Total (ms)
%  - Average RBs/HO
%  - Average RBs (absolute)

% ===== Fixed evaluation sample count (all MAT files are truncated to this N) =====
% [] 로 두면 자동(공통 최소 샘플 수) 사용
FIXED_N_SAMPLES = 2000;

% ===== HO rate plot options =====
% 'per_min' (분당), 'per_sec' (초당)
HO_RATE_UNIT = 'per_min';
% 비우면 자동 추정, 값 지정 시 해당 값(초) 사용
SIM_TIME_SEC_OVERRIDE = [];
% 자동 추정 시 RAW 시계열 길이로 환산할 때 사용할 기본 샘플 시간
DEFAULT_SAMPLE_TIME_SEC = 0.2;


resultsDir = fileparts(mfilename('fullpath'));

% targetStrategies = { ...
%     'Strategy BHO-CFRA', ...
%     'Strategy CHO-CFRA', ...
%     'Strategy CHO-RAL', ...
%     'Strategy A3T1-CHO-RAL'};

targetStrategies = { ...
    'Strategy BHO-CFRA', ...
    'Strategy CHO-CFRA', ...
    'Strategy CHO-RAL', ...
    'Strategy A3T1-CHO-RAL(R-2km)', ...
    'Strategy A3T1-CHO-RAL(R-1km)', ...
    'Strategy A3T1-CHO-RAL', ...
    'Strategy A3T1-CHO-RAL(R+1km)', ...
    'Strategy A3T1-CHO-RAL(R+2km)'};

% targetStrategies = { ...
%     'Strategy BHO-CFRA', ...
%     'Strategy CHO-CFRA', ...
%     'Strategy CHO-RAL', ...
%     'Strategy DCHO-CFRA', ...
%     'Strategy DCHO-RAL', ...
%     'Strategy A3T1-CHO-RAL', ...
%     'Strategy D2T1-CHO-RAL'};

files = struct([]);
labels = {};
allMat = dir(fullfile(resultsDir, '*_MASTER_RESULTS_*.mat'));

strategyCandidates = cell(1, numel(targetStrategies));
for k = 1:numel(targetStrategies)
    strategyToken = targetStrategies{k};
    hit = false(size(allMat));
    for j = 1:numel(allMat)
        hit(j) = match_strategy_token(allMat(j).name, strategyToken);
    end
    f = allMat(hit);
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

% 공통 N_samples가 존재하면, 해당 N 중에서 가장 최신(전략별 최신 파일들의 최소 datenum 최대) 세트를 선택
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
        for k = 1:numel(files)
            labels{end+1} = strrep(targetStrategies{k}, 'Strategy ', ''); %#ok<SAGROW>
        end
        fprintf('Using fairness-matched set: common N_samples=%d across all target strategies.\n', bestN);
        usedFairSet = true;
    end
end

if ~usedFairSet
    % fallback: 기존 방식(전략별 최신 파일)
    for k = 1:numel(targetStrategies)
        strategyToken = targetStrategies{k};
        hit = false(size(allMat));
        for j = 1:numel(allMat)
            hit(j) = match_strategy_token(allMat(j).name, strategyToken);
        end
        f = allMat(hit);
        if ~isempty(f)
            [~, ix] = max([f.datenum]);
            if isempty(files)
                files = f(ix);
            else
                files(end+1) = f(ix); %#ok<SAGROW>
            end
            labels{end+1} = strrep(targetStrategies{k}, 'Strategy ', ''); %#ok<SAGROW>
        end
    end
    warning('Could not build fairness-matched common N set. Fallback to latest-per-strategy files.');
end

 if numel(files) < numel(targetStrategies)
     requestedList = strjoin(strrep(targetStrategies, 'Strategy ', ''), '/');
     error('비교용 파일이 부족합니다. 요청한 %d개 전략(%s) 결과 MAT를 확인하세요.', numel(targetStrategies), requestedList);
end

nFile = numel(files);
data = cell(1, nFile);
filePaths = cell(1, nFile);
for k = 1:nFile
    filePaths{k} = fullfile(resultsDir, files(k).name);
    data{k} = load(filePaths{k});
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
        error('FIXED_N_SAMPLES=%d exceeds available samples in at least one MAT (available: %s).', nEval, mat2str(availSamples));
    end
    fprintf('Using configured fixed N_samples=%d for all target strategies.\n', nEval);
end

vec = @(x) x(:);
mMIT = zeros(1, nFile);
mRBs = zeros(1, nFile);
mRBsPerHO = zeros(1, nFile);
mHO = zeros(1, nFile);
mTotalHO = zeros(1, nFile);
mHORate = zeros(1, nFile);
mEssentialHORate = zeros(1, nFile);
mUHOPureRate = zeros(1, nFile);
mHOPPRate = zeros(1, nFile);
mTotalHORateBreakdown = zeros(1, nFile);
mNSamples = zeros(1, nFile);
mDynTx = zeros(1, nFile);
mRachRB = zeros(1, nFile);
mUHOCount = zeros(1, nFile);
mUHOProb = zeros(1, nFile);
mRLFProb = zeros(1, nFile);
mShortToSProb = zeros(1, nFile);
mHOPPProb = zeros(1, nFile);
sinrDataAll = cell(1, nFile);
tosDataAll = cell(1, nFile);
avgToS = zeros(1, nFile);

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
    rb_vec = get_field_vec_n(d, 'MASTER_RBs', nEval);
    ho_vec = get_field_vec_n(d, 'MASTER_HO', nEval);

    if ~isempty(mit_total_vec)
        mMIT(k) = mean(mit_total_vec) * 1e3;  % ms
    else
        mMIT(k) = NaN;
    end

    if ~isempty(rb_vec)
        mRBs(k) = mean(rb_vec);
        totalRB = sum(rb_vec);
    else
        mRBs(k) = NaN;
        totalRB = 0;
    end

    if ~isempty(ho_vec)
        mHO(k) = mean(ho_vec);
        totalHO = sum(ho_vec);
        mTotalHO(k) = totalHO;
        if ~isnan(simTimeSec) && simTimeSec > 0
            mHORate(k) = (mHO(k) / simTimeSec) * hoRateScale;
        else
            mHORate(k) = NaN;
        end
        mNSamples(k) = numel(ho_vec);
    else
        totalHO = 0;
        mTotalHO(k) = 0;
        mHORate(k) = NaN;
        mNSamples(k) = 0;
    end

    if totalHO > 0
        mRBsPerHO(k) = totalRB / totalHO;
    else
        mRBsPerHO(k) = NaN;
    end
    dyn_tx_vec = get_field_vec_n(d, 'MASTER_DYN_GRANT_TX_COUNT', nEval);
    if ~isempty(dyn_tx_vec), mDynTx(k) = mean(dyn_tx_vec); end

    rach_rb_vec = get_field_vec_n(d, 'MASTER_RACH_RB_EQ', nEval);
    if ~isempty(rach_rb_vec), mRachRB(k) = mean(rach_rb_vec); end

    uho_vec = get_field_vec_n(d, 'MASTER_UHO', nEval);
    hopp_vec = get_field_vec_n(d, 'MASTER_HOPP', nEval);
    rlf_vec = get_field_vec_n(d, 'MASTER_RLF', nEval);

    if ~isempty(uho_vec)
        mUHOCount(k) = mean(uho_vec);
    else
        mUHOCount(k) = 0;
    end

    ho_sum = sum(ho_vec);
    uho_sum = sum(uho_vec);
    hopp_sum = sum(hopp_vec);

    if ~isempty(ho_vec) && ~isnan(simTimeSec) && simTimeSec > 0
        normFactor = hoRateScale / (numel(ho_vec) * simTimeSec); % [#/UE/min] 또는 [#/UE/sec]
        essential_cnt = max(0, ho_sum - uho_sum);
        pure_uho_cnt = max(0, uho_sum - hopp_sum);
        hopp_cnt = max(0, hopp_sum);

        mEssentialHORate(k) = essential_cnt * normFactor;
        mUHOPureRate(k) = pure_uho_cnt * normFactor;
        mHOPPRate(k) = hopp_cnt * normFactor;
        mTotalHORateBreakdown(k) = mEssentialHORate(k) + mUHOPureRate(k) + mHOPPRate(k);
    else
        mEssentialHORate(k) = NaN;
        mUHOPureRate(k) = NaN;
        mHOPPRate(k) = NaN;
        mTotalHORateBreakdown(k) = NaN;
    end

    if ho_sum > 0
        mUHOProb(k) = (uho_sum / ho_sum) * 100;
        mHOPPProb(k) = (hopp_sum / ho_sum) * 100;
    else
        mUHOProb(k) = 0;
        mHOPPProb(k) = 0;
    end

    if ~isempty(rlf_vec)
        mRLFProb(k) = mean(rlf_vec);  % APWCS: average RLF per UE
    else
        mRLFProb(k) = 0;
    end

    if isfield(d, 'MASTER_ToS') && ~isempty(d.MASTER_ToS)
        tos_data = d.MASTER_ToS(:);
        total_tos_count = numel(tos_data);
        short_tos_count = sum(tos_data < 1);
        if total_tos_count > 0
            mShortToSProb(k) = (short_tos_count / total_tos_count) * 100;
        else
            mShortToSProb(k) = 0;
        end
    else
        mShortToSProb(k) = 0;
    end

    sinrDataAll{k} = get_field_vec_n(d, 'MASTER_SINR', nEval);

    if isfield(d, 'MASTER_ToS') && ~isempty(d.MASTER_ToS)
        tosDataAll{k} = d.MASTER_ToS(:);
    else
        tosDataAll{k} = [];
    end
    if ~isempty(tosDataAll{k})
        avgToS(k) = mean(tosDataAll{k});
    else
        avgToS(k) = NaN;
    end
end

figure('Name',sprintf('MIT & RB Metrics Compare (%d Sets)', nFile),'Color','w');
tiledlayout(1,3, 'Padding','compact', 'TileSpacing','compact');

setColors = lines(nFile);

nexttile;
b1 = bar(mMIT); grid on;
b1.FaceColor = 'flat';
b1.CData = setColors(1:nFile, :);
title('Average MIT Total (ms)');
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);

nexttile;
b2 = bar(mRBsPerHO); grid on;
b2.FaceColor = 'flat';
b2.CData = setColors(1:nFile, :);
title('Average RBs/HO (normalized)');
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);

nexttile;
b3 = bar(mRBs); grid on;
b3.FaceColor = 'flat';
b3.CData = setColors(1:nFile, :);
title('Average RBs (absolute)');
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);

T = table(labels(:), mNSamples(:), mMIT(:), mRBsPerHO(:), mRBs(:), mHO(:), mHORate(:), mRachRB(:), (mRBs(:)-mRachRB(:)), mDynTx(:), ...
    mUHOCount(:), ...
    'VariableNames', {'ResultSet','N_samples','Avg_MIT_ms','Avg_RBs_per_HO','Avg_RBs','Avg_HO','Avg_HO_Rate','Avg_RACH_RBs','Avg_RBs_minus_RACH','Avg_DynGrant_Tx','Avg_UHO_per_UE'});
disp(sprintf('=== Compare Summary (%d Sets, 2 Metrics) ===', nFile));
disp('(*) Avg_MIT_ms is computed from direct MIT interval: detach -> HO complete RX');
disp('(*) Avg_RBs contains fixed HO control overhead + RACH-related + dynamic-grant overhead');
if any(mNSamples ~= mNSamples(1))
    warning('Compared result sets have different sample sizes (N_samples). Fairness may be affected.');
end
disp(T);

figColors = lines(nFile);

figure('Name','RLF per UE','Color','w');
bRLF = bar(mRLFProb, 'FaceColor', 'flat');
bRLF.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel('Average RLF [#operations/UE]');
title('RLF (APWCS-style)');
if max(mRLFProb) > 0
    ylim([0, max(mRLFProb) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    text(i, mRLFProb(i) + max(1e-3, max(mRLFProb)*0.02), sprintf('%.3f', mRLFProb(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end

figure('Name','UHO per HO','Color','w');
bUHO = bar(mUHOProb, 'FaceColor', 'flat');
bUHO.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel('UHO/HO ratio (%)');
title('UHO/HO (APWCS-style)');
if max(mUHOProb) > 0
    ylim([0, max(mUHOProb) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    text(i, mUHOProb(i) + max(1e-3, max(mUHOProb)*0.02), sprintf('%.3f', mUHOProb(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end

figure('Name','UHO count','Color','w');
bUHOCount = bar(mUHOCount, 'FaceColor', 'flat');
bUHOCount.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel('Average UHO [#operations/UE]');
title('UHO count (absolute)');
if max(mUHOCount) > 0
    ylim([0, max(mUHOCount) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    text(i, mUHOCount(i) + max(1e-3, max(mUHOCount)*0.02), sprintf('%.3f', mUHOCount(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end

switch lower(strtrim(HO_RATE_UNIT))
    case 'per_min'
        hoRateLabel = 'HO rate [#events/UE/min]';
        hoRateTitle = 'HO rate (normalized by simulation time, per minute)';
        hoRateFileSuffix = 'per_min';
    case 'per_sec'
        hoRateLabel = 'HO rate [#events/UE/sec]';
        hoRateTitle = 'HO rate (normalized by simulation time, per second)';
        hoRateFileSuffix = 'per_sec';
end

figure('Name','HO rate','Color','w');
bHOCount = bar(mHORate, 'FaceColor', 'flat');
bHOCount.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel(hoRateLabel);
title(hoRateTitle);
validHORate = mHORate(~isnan(mHORate));
if ~isempty(validHORate) && max(validHORate) > 0
    ylim([0, max(validHORate) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    yv = mHORate(i);
    if isnan(yv)
        continue;
    end
    if ~isempty(validHORate)
        yOffset = max(1e-3, max(validHORate)*0.02);
    else
        yOffset = 1e-3;
    end
    text(i, yv + yOffset, sprintf('%.2f', yv), ...
        'HorizontalAlignment','center','FontSize',9);
end
savefig(fullfile(resultsDir, ['compare_HO_rate_' hoRateFileSuffix '.fig']));
saveas(gcf, fullfile(resultsDir, ['compare_HO_rate_' hoRateFileSuffix '.png']));

figure('Name','HO Efficiency Breakdown','Color','w');
stackedHO = [mEssentialHORate(:), mUHOPureRate(:), mHOPPRate(:)];
bEff = bar(stackedHO, 'stacked', 'BarWidth', 0.62);
bEff(1).FaceColor = [0.2 0.6 0.2];   % Essential
bEff(2).FaceColor = [0.8 0.2 0.2];   % UHO
bEff(3).FaceColor = [0.5 0.0 0.5];   % HOPP
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);

switch lower(strtrim(HO_RATE_UNIT))
    case 'per_min'
        effLabel = 'Average HOs [#/UE/min.]';
    case 'per_sec'
        effLabel = 'Average HOs [#/UE/sec.]';
end
ylabel(effLabel);

% title('HO Efficiency Breakdown (Essential / UHO / HOPP)');

% legend + wasted ratio meaning
lgd = legend( ...
    {'Essential HO (Valid)', 'Wasted HO (UHO)', 'Wasted HO (HOPP)', 'Blue text: Wasted ratio (%)'}, ...
    'Location', 'northeast');
lgd.Box = 'on';

validTot = mTotalHORateBreakdown(~isnan(mTotalHORateBreakdown));
if ~isempty(validTot) && max(validTot) > 0
    ylim([0, max(validTot) * 1.22]);
else
    ylim([0, 1]);
end

% ---- only percentage text, in blue, with overlap mitigation ----
for i = 1:nFile
    totalVal = mTotalHORateBreakdown(i);
    if isnan(totalVal)
        continue;
    end

    wastedVal = mUHOPureRate(i) + mHOPPRate(i);
    if totalVal > 0
        wastePct = (wastedVal / totalVal) * 100;
    else
        wastePct = 0;
    end

    % 기본 오프셋
    if ~isempty(validTot)
        baseOffset = max(validTot) * 0.015;
    else
        baseOffset = 0.02;
    end

    % 인접 막대끼리 높이가 비슷하면 텍스트 높이를 교대로 살짝 벌림
    extraOffset = 0;
    if i >= 2
        prevVal = mTotalHORateBreakdown(i-1);
        if ~isnan(prevVal)
            if abs(totalVal - prevVal) < 0.35
                extraOffset = max(validTot) * 0.03 * mod(i,2);
            end
        end
    end

    text(i, totalVal + baseOffset + extraOffset, sprintf('%.1f%%', wastePct), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'Color', [0.0 0.35 0.90]);   % blue text
end

savefig(fullfile(resultsDir, ['compare_HO_efficiency_breakdown_' hoRateFileSuffix '.fig']));
saveas(gcf, fullfile(resultsDir, ['compare_HO_efficiency_breakdown_' hoRateFileSuffix '.png']));

figure('Name','HO Efficiency Breakdown','Color','w');
stackedHO = [mEssentialHORate(:), mUHOPureRate(:), mHOPPRate(:)];
bEff = bar(stackedHO, 'stacked', 'BarWidth', 0.6);
bEff(1).FaceColor = [0.2 0.6 0.2];
bEff(2).FaceColor = [0.8 0.2 0.2];
bEff(3).FaceColor = [0.5 0.0 0.5];
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);

switch lower(strtrim(HO_RATE_UNIT))
    case 'per_min'
        effLabel = 'Average HOs [#/UE/min.]';
    case 'per_sec'
        effLabel = 'Average HOs [#/UE/sec.]';
end
ylabel(effLabel);
% title('HO Efficiency Breakdown (Essential / UHO / HOPP)');
legend({'Essential HO (Valid)', 'Wasted HO (UHO)', 'Wasted HO (HOPP)'}, 'Location', 'northeast');

validTot = mTotalHORateBreakdown(~isnan(mTotalHORateBreakdown));
if ~isempty(validTot) && max(validTot) > 0
    ylim([0, max(validTot) * 1.35]);
else
    ylim([0, 1]);
end

for i = 1:nFile
    totalVal = mTotalHORateBreakdown(i);
    if isnan(totalVal)
        continue;
    end
    wastedVal = mUHOPureRate(i) + mHOPPRate(i);
    if totalVal > 0
        wastePct = (wastedVal / totalVal) * 100;
    else
        wastePct = 0;
    end
    labelStr = sprintf('%.1f%% Wasted\n(%.2f)', wastePct, totalVal);
    if ~isempty(validTot)
        yOffset = max(validTot) * 0.02;
    else
        yOffset = 0.02;
    end
    text(i, totalVal + yOffset, labelStr, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 9, 'Color', 'k', 'FontWeight', 'bold');
end
savefig(fullfile(resultsDir, ['compare_HO_efficiency_breakdown_' hoRateFileSuffix '.fig']));
saveas(gcf, fullfile(resultsDir, ['compare_HO_efficiency_breakdown_' hoRateFileSuffix '.png']));

figure('Name','HOPP per HO','Color','w');
bHOPP = bar(mHOPPProb, 'FaceColor', 'flat');
bHOPP.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel('PP/HO ratio (%)');
title('HOPP/HO (APWCS-style)');
if max(mHOPPProb) > 0
    ylim([0, max(mHOPPProb) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    text(i, mHOPPProb(i) + max(1e-3, max(mHOPPProb)*0.02), sprintf('%.3f', mHOPPProb(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end

figure('Name','ShortToS ratio','Color','w');
bSTS = bar(mShortToSProb, 'FaceColor', 'flat');
bSTS.CData = figColors(1:nFile, :);
grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
ylabel('Short ToS ratio (%)');
title('Short ToS ratio (APWCS-style)');
if max(mShortToSProb) > 0
    ylim([0, max(mShortToSProb) * 1.15]);
else
    ylim([0, 1]);
end
for i = 1:nFile
    text(i, mShortToSProb(i) + max(1e-3, max(mShortToSProb)*0.02), sprintf('%.3f', mShortToSProb(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end

% Copy_of_SCI style: DL SINR 분포(box) + CDF
sinrBoxVals = [];
sinrGroups = [];
for i = 1:nFile
    if ~isempty(sinrDataAll{i})
        sinrBoxVals = [sinrBoxVals; sinrDataAll{i}]; %#ok<AGROW>
        sinrGroups = [sinrGroups; i*ones(numel(sinrDataAll{i}),1)]; %#ok<AGROW>
    end
end

if ~isempty(sinrBoxVals)
    figure('Name','DL SINR Boxplot','Color','w');
    boxplot(sinrBoxVals, sinrGroups, 'Labels', labels);
    ylabel('Average DL SINR [dB]');
    set(gca, 'XTickLabelRotation', 20);
    grid on; grid minor;

    figure('Name','DL SINR CDF','Color','w');
    hold on;
    for i = 1:nFile
        if ~isempty(sinrDataAll{i})
            [cdfSINR, xSINR] = ecdf(sinrDataAll{i});
            plot(xSINR, cdfSINR, 'LineWidth', 1.6, 'Color', figColors(i,:), 'DisplayName', labels{i});
        end
    end
    hold off;
    xlabel('DL SINR [dB]');
    ylabel('CDF');
    legend('Location','best');
    grid on; grid minor;
end

% Copy_of_SCI style: Average ToS + Short ToS ratio
if any(~isnan(avgToS))
    figure('Name','Average ToS','Color','w');
    bToS = bar(avgToS, 'FaceColor','flat');
    bToS.CData = figColors(1:nFile,:);
    set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
    ylabel('Average Time-of-Stay [s]');
    title('Average ToS');
    grid on; grid minor;
    maxToS = max(avgToS(~isnan(avgToS)));
    ylim([0, maxToS*1.15]);
end

% Additional combined view: Average ToS + ShortToS ratio
if any(~isnan(avgToS))
    figure('Name','Average ToS + ShortToS ratio','Color','w');

    yyaxis left;
    bToSComb = bar(1:nFile, avgToS, 0.58, ...
        'FaceColor', [0.20 0.50 0.85], ...
        'EdgeColor', [0.12 0.34 0.62]);
    bToSComb.FaceAlpha = 0.45;
    ylabel('Average Time-of-Stay [s]');
    validToS = avgToS(~isnan(avgToS));
    if isempty(validToS)
        ylim([0, 1]);
    else
        ylim([0, max(validToS) * 1.25]);
    end

    yyaxis right;
    pSTSComb = plot(1:nFile, mShortToSProb, '-o', ...
        'LineWidth', 2.2, ...
        'Color', [0.85 0.33 0.10], ...
        'MarkerFaceColor', [0.85 0.33 0.10], ...
        'MarkerSize', 8);
    ylabel('Short ToS ratio (%)');
    if max(mShortToSProb) > 0
        ylim([0, max(mShortToSProb) * 1.35]);
    else
        ylim([0, 1]);
    end

    grid on; grid minor;
    set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
    % title('Average ToS and Short ToS ratio');
    legend([bToSComb, pSTSComb], {'Average ToS [s]', 'Short ToS ratio [%]'}, 'Location', 'northeast');

    savefig(fullfile(resultsDir, 'compare_avgToS_shortToS_combined.fig'));
    saveas(gcf, fullfile(resultsDir, 'compare_avgToS_shortToS_combined.png'));
end

TRel = table(labels(:), mUHOProb(:), mUHOCount(:), mRLFProb(:), mShortToSProb(:), mHOPPProb(:), ...
    'VariableNames', {'ResultSet','UHO_prob','Avg_UHO_per_UE','RLF_prob','ShortToS_prob','HOPP_prob'});
disp('=== HO Reliability Summary (APWCS-style aggregation) ===');
disp(TRel);

% -------------------------------------------------------------------------
% Improved view: MIT + RBs/HO (cleaner grouped-bar + line overlay)
% 기존 그래프는 유지하고, 보기 좋은 추가 버전만 생성
% -------------------------------------------------------------------------
figure('Name','MIT + RBs/HO Combined (Improved)','Color','w');

x = 1:nFile;

yyaxis left;
bMIT = bar(x, mMIT, 0.62, ...
    'FaceColor', [0.86 0.33 0.31], ...
    'EdgeColor', [0.55 0.18 0.18], ...
    'FaceAlpha', 0.80);
ylabel('Mobility interruption time (ms)');
axImp = gca;
axImp.YAxis(1).Color = [0.55 0.18 0.18];
validMIT = mMIT(~isnan(mMIT));
if isempty(validMIT)
    ylim([0, 1]);
else
    ylim([0, max(validMIT) * 1.25]);
end

% MIT bar value labels
for i = 1:nFile
    if ~isnan(mMIT(i))
        text(i, mMIT(i) + max(validMIT)*0.02, sprintf('%.2f', mMIT(i)), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize', 9, ...
            'Color', [0.45 0.10 0.10], ...
            'FontWeight', 'bold');
    end
end

yyaxis right;
pRB = plot(x, mRBsPerHO, '-o', ...
    'LineWidth', 2.2, ...
    'Color', [0.12 0.38 0.80], ...
    'MarkerFaceColor', [0.12 0.38 0.80], ...
    'MarkerSize', 7);
ylabel('RBs per HO');
axImp.YAxis(2).Color = [0.12 0.38 0.80];
validRB = mRBsPerHO(~isnan(mRBsPerHO));
if isempty(validRB)
    ylim([0, 1]);
else
    ylim([0, max(validRB) * 1.25]);
end

% RB/HO point labels
for i = 1:nFile
    if ~isnan(mRBsPerHO(i))
        text(i, mRBsPerHO(i) + max(validRB)*0.03, sprintf('%.2f', mRBsPerHO(i)), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize', 9, ...
            'Color', [0.05 0.22 0.55], ...
            'FontWeight', 'bold');
    end
end

grid on;
set(gca, 'XTick', x, 'XTickLabel', labels, 'XTickLabelRotation', 20);
title('MIT and RBs/HO Comparison');
legend([bMIT, pRB], {'MIT (ms)', 'RBs/HO'}, 'Location', 'northwest');

savefig(fullfile(resultsDir, 'compare_MIT_RBs_combined_improved.fig'));
saveas(gcf, fullfile(resultsDir, 'compare_MIT_RBs_combined_improved.png'));

figure('Name','MIT + RBs/HO Combined','Color','w');
yyaxis right;
bComb = bar(1:nFile, mRBsPerHO, 0.55, 'FaceColor', [0.70 0.70 0.92], 'EdgeColor', [0.55 0.55 0.75]);
bComb.FaceAlpha = 0.50;
ylabel('RBs/HO');
axComb = gca;
axComb.YAxis(2).Color = [0.55 0.55 0.75];
validRB = mRBsPerHO(~isnan(mRBsPerHO));
if isempty(validRB)
    ylim([0, 1]);
else
    ylim([0, max(validRB) * 1.15]);
end

yyaxis left;
pComb = plot(1:nFile, mMIT, '-o', 'Color', [0.70 0.20 0.20], 'LineWidth', 1.8, 'MarkerFaceColor', [0.70 0.20 0.20]);
ylabel('Mobility interruption time (ms)');
axComb.YAxis(1).Color = [0.70 0.20 0.20];
if max(mMIT) <= 0
    ylim([0, 1]);
else
    ylim([0, max(mMIT) * 1.15]);
end

grid on;
set(gca, 'XTick', 1:nFile, 'XTickLabel', labels, 'XTickLabelRotation', 20);
% title('MIT (left) and RBs/HO (right) by HO Method');
legend([pComb, bComb], {'MIT (ms)','RBs/HO'}, 'Location', 'northeast');

disp('Loaded files:');
for k = 1:nFile
    fprintf('  %s\n', filePaths{k});
end

function tf = match_strategy_token(fileName, strategyToken)
    fileStrategy = extract_strategy_name(fileName);
    if isempty(fileStrategy)
        tf = false;
        return;
    end

    switch strategyToken
        case 'Strategy BHO-CFRA'
            tf = strcmp(fileStrategy, 'BHO-CFRA') || strcmp(fileStrategy, 'BHO');
        case 'Strategy CHO-CFRA'
            tf = strcmp(fileStrategy, 'CHO-CFRA') || strcmp(fileStrategy, 'CHO0-CFRA');
        case 'Strategy CHO-RAL'
            tf = strcmp(fileStrategy, 'CHO-RAL') || strcmp(fileStrategy, 'CHO0-RAL');
        case 'Strategy DCHO-CFRA'
            tf = strcmp(fileStrategy, 'DCHO-CFRA') || strcmp(fileStrategy, 'DDRCHO-CFRA') || strcmp(fileStrategy, 'DCHO1');
        case 'Strategy DCHO-RAL'
            tf = strcmp(fileStrategy, 'DCHO-RAL') || strcmp(fileStrategy, 'DDRCHO-RACHless') || strcmp(fileStrategy, 'DRLCHO');
        case {'Strategy A3T1-CHO-RAL', 'Strategy A3T1-CHO-RAL_0'}
            tf = strcmp(fileStrategy, 'A3T1-CHO-RAL') || strcmp(fileStrategy, 'A3T1-RAL');
        case {'Strategy A3T1-CHO-RAL(R-2km)', 'Strategy A3T1-CHO-RAL_-2'}
            tf = strcmp(fileStrategy, 'A3T1-CHO-RAL(R-2km)') || strcmp(fileStrategy, 'A3T1-CHO-RAL_-2') || strcmp(fileStrategy, 'A3T1-RAL_-2');
        case {'Strategy A3T1-CHO-RAL(R-1km)', 'Strategy A3T1-CHO-RAL_-1'}
            tf = strcmp(fileStrategy, 'A3T1-CHO-RAL(R-1km)') || strcmp(fileStrategy, 'A3T1-CHO-RAL_-1') || strcmp(fileStrategy, 'A3T1-RAL_-1');
        case {'Strategy A3T1-CHO-RAL(R+1km)', 'Strategy A3T1-CHO-RAL_+1'}
            tf = strcmp(fileStrategy, 'A3T1-CHO-RAL(R+1km)') || strcmp(fileStrategy, 'A3T1-CHO-RAL_+1') || strcmp(fileStrategy, 'A3T1-RAL_+1');
        case {'Strategy A3T1-CHO-RAL(R+2km)', 'Strategy A3T1-CHO-RAL_+2'}
            tf = strcmp(fileStrategy, 'A3T1-CHO-RAL(R+2km)') || strcmp(fileStrategy, 'A3T1-CHO-RAL_+2') || strcmp(fileStrategy, 'A3T1-RAL_+2');
        case 'Strategy D2T1-CHO-RAL'
            tf = strcmp(fileStrategy, 'D2T1-CHO-RAL') || strcmp(fileStrategy, 'D2T1-RAL');
        otherwise
            tf = contains(fileName, strategyToken);
    end
end

function strategyName = extract_strategy_name(fileName)
    strategyName = '';
    tok = regexp(fileName, 'Strategy\s+(.+?)_K', 'tokens', 'once');
    if ~isempty(tok)
        strategyName = strtrim(tok{1});
    end
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
