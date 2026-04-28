clear; clc; close all;

%% ===== User options =====
FIXED_N_SAMPLES = 2000;       % [] 이면 공통 최소 샘플 수 사용
HO_RATE_UNIT = 'per_min';     % 'per_min' or 'per_sec'
SIM_TIME_SEC_OVERRIDE = [];   % 필요 시 직접 지정
DEFAULT_SAMPLE_TIME_SEC = 0.2;

resultsDir = fileparts(mfilename('fullpath'));

% ===== Strategy order =====
targetStrategies = { ...
    'Strategy BHO-CFRA', ...
    'Strategy CHO-CFRA', ...
    'Strategy CHO-RAL', ...
    'Strategy A3T1-CHO-RAL', ...
    'Strategy A3T1-CHO-RAL(R-2km)', ...
    'Strategy A3T1-CHO-RAL(R-1km)', ...
    'Strategy A3T1-CHO-RAL(R+1km)', ...
    'Strategy A3T1-CHO-RAL(R+2km)'};


%% ===== Load candidate MAT files =====
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
        for k = 1:numel(files)
            labels{end+1} = strrep(targetStrategies{k}, 'Strategy ', ''); %#ok<SAGROW>
        end
        fprintf('Using fairness-matched set: common N_samples=%d across all target strategies.\n', bestN);
        usedFairSet = true;
    end
end

if ~usedFairSet
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
    error('비교용 파일이 부족합니다. 요청한 %d개 전략(%s) 결과 MAT를 확인하세요.', ...
        numel(targetStrategies), requestedList);
end

%% ===== Load full MAT contents =====
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
sinrDataAll        = cell(1, nFile);

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
    sinrDataAll{k} = sinr_vec;

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
% mWastedProb = mUHOProb + mHOPPProb;   % ratio 기준 UHO+HOPP
mWastedProb = mUHOProb;
mWastedRate = mUHOPureRate + mHOPPRate;

%% ===== Plot subset indices =====
idxMain = [1 2 3 4];     % BHO / CHO-CFRA / CHO-RAL / A3T1-CHO-RAL
idxVar  = [5 6 4 7 8];   % R-2 / R-1 / base / R+1 / R+2

% labelsMain = labels(idxMain);
labelsMain = {'BHO-CFRA', 'CHO-CFRA', 'CHO-RAL', 'Proposed'};
labelsVar  = {'\Delta_{off}=-t_{2km}', '\Delta_{off}=-t_{1km}', ...
    '\Delta_{off}=0', '\Delta_{off}=t_{1km}', '\Delta_{off}=t_{2km}'};

%% =======================================================================
% Fig1: MIT + RBs/HO (main4)
% ========================================================================
figure('Name', 'Fig1_MIT_RBs_main4', 'Color', 'w');

x = 1:numel(idxMain);

yyaxis left;
bMIT = bar(x - 0.17, mMIT(idxMain), 0.34, ...
    'FaceColor', [0.86 0.33 0.31], ...
    'EdgeColor', [0.55 0.18 0.18], ...
    'FaceAlpha', 0.82);
ylabel('Average MIT [ms]');
ax1 = gca;
ax1.YAxis(1).Color = [0.55 0.18 0.18];

validMIT = mMIT(idxMain);
validMIT = validMIT(~isnan(validMIT));
if isempty(validMIT)
    ylim([0 1]);
else
    ylim([0 max(validMIT)*1.22]);
end

yoffMIT = 0.02 * max([validMIT(:); 1]);
for i = 1:numel(idxMain)
    yv = mMIT(idxMain(i));
    if ~isnan(yv)
        text(x(i)-0.17, yv + yoffMIT, sprintf('%.2f', yv), ...
            'HorizontalAlignment', 'center', 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', [0.45 0.10 0.10]);
    end
end

yyaxis right;
bRB = bar(x + 0.17, mRBsPerHO(idxMain), 0.34, ...
    'FaceColor', [0.22 0.48 0.84], ...
    'EdgeColor', [0.10 0.25 0.55], ...
    'FaceAlpha', 0.78);
ylabel('Average RBs/HO');
ax1.YAxis(2).Color = [0.10 0.25 0.55];

validRB = mRBsPerHO(idxMain);
validRB = validRB(~isnan(validRB));
if isempty(validRB)
    ylim([0 1]);
else
    ylim([0 max(validRB)*1.25]);
end

yoffRB = 0.03 * max([validRB(:); 1]);
for i = 1:numel(idxMain)
    yv = mRBsPerHO(idxMain(i));
    if ~isnan(yv)
        text(x(i)+0.17, yv + yoffRB, sprintf('%.2f', yv), ...
            'HorizontalAlignment', 'center', 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', [0.05 0.22 0.55]);
    end
end

grid on;
set(gca, 'XTick', x, 'XTickLabel', labelsMain, 'XTickLabelRotation', 18);
% title('MIT and RBs/HO Comparison');
legend([bMIT, bRB], {'MIT (ms)', 'RBs/HO'}, 'Location', 'northwest');

savefig(fullfile(resultsDir, 'Fig1_MIT_RBs_main4.fig'));
saveas(gcf, fullfile(resultsDir, 'Fig1_MIT_RBs_main4.png'));

%% =======================================================================
% Fig2: HO Efficiency Breakdown (main4)
%   Essential / UHO / HOPP
%   robust manual stacked drawing
% ========================================================================
figure('Name','Fig2_HOEfficiency_main4','Color','w');
clf;

ax2 = gca;
cla(ax2, 'reset');
hold(ax2, 'on');
grid(ax2, 'on');

x = 1:numel(idxMain);
barW = 0.62;

yEssential = mEssentialHORate(idxMain(:));
yUHO       = mUHOPureRate(idxMain(:));
yHOPP      = mHOPPRate(idxMain(:));

cEssential = [0.2 0.6 0.2];
cUHO       = [0.8 0.2 0.2];
cHOPP      = [0.5 0.0 0.5];

eEssential = [0.15 0.35 0.15];
eUHO       = [0.45 0.10 0.10];
eHOPP      = [0.28 0.00 0.28];

for ii = 1:numel(x)
    left = x(ii) - barW/2;

    % Essential
    rectangle(ax2, ...
        'Position', [left, 0, barW, yEssential(ii)], ...
        'FaceColor', cEssential, ...
        'EdgeColor', eEssential, ...
        'LineWidth', 1.0);

    % UHO
    if yUHO(ii) > 0
        rectangle(ax2, ...
            'Position', [left, yEssential(ii), barW, yUHO(ii)], ...
            'FaceColor', cUHO, ...
            'EdgeColor', eUHO, ...
            'LineWidth', 1.0);
    end

    % HOPP
    if yHOPP(ii) > 0
        rectangle(ax2, ...
            'Position', [left, yEssential(ii) + yUHO(ii), barW, yHOPP(ii)], ...
            'FaceColor', cHOPP, ...
            'EdgeColor', eHOPP, ...
            'LineWidth', 1.0);
    end
end

set(ax2, ...
    'XTick', x, ...
    'XTickLabel', labelsMain, ...
    'XTickLabelRotation', 18);

xlim(ax2, [0.4, numel(idxMain)+0.6]);

switch lower(strtrim(HO_RATE_UNIT))
    case 'per_min'
        effLabel = 'Average HOs [#/UE/min.]';
    case 'per_sec'
        effLabel = 'Average HOs [#/UE/sec.]';
end
ylabel(ax2, effLabel);
% title(ax2, 'HO Efficiency Breakdown (Essential / UHO / HOPP)');

validTot = mTotalHORateBreakdown(idxMain);
validTot = validTot(~isnan(validTot));
if ~isempty(validTot) && max(validTot) > 0
    ylim(ax2, [0, max(validTot) * 1.22]);
else
    ylim(ax2, [0, 1]);
end

% ---- blue wasted percentage text ----
for ii = 1:numel(idxMain)
    k = idxMain(ii);

    totalVal = mTotalHORateBreakdown(k);
    if isnan(totalVal)
        continue;
    end

    wastedVal = mUHOPureRate(k) + mHOPPRate(k);
    if totalVal > 0
        wastePct = (wastedVal / totalVal) * 100;
    else
        wastePct = 0;
    end

    if ~isempty(validTot)
        baseOffset = max(validTot) * 0.015;
    else
        baseOffset = 0.02;
    end

    extraOffset = 0;
    if ii >= 2
        prevVal = mTotalHORateBreakdown(idxMain(ii-1));
        if ~isnan(prevVal) && abs(totalVal - prevVal) < 0.35
            extraOffset = max(validTot) * 0.03 * mod(ii,2);
        end
    end

    text(ax2, ii, totalVal + baseOffset + extraOffset, sprintf('%.1f%%', wastePct), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'Color', [0.0 0.35 0.90]);
end

% ---- legend dummy handles ----
h1 = plot(ax2, nan, nan, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', cEssential, ...
    'MarkerEdgeColor', eEssential, ...
    'LineStyle', 'none');
h2 = plot(ax2, nan, nan, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', cUHO, ...
    'MarkerEdgeColor', eUHO, ...
    'LineStyle', 'none');
h3 = plot(ax2, nan, nan, 's', 'MarkerSize', 10, ...
    'MarkerFaceColor', cHOPP, ...
    'MarkerEdgeColor', eHOPP, ...
    'LineStyle', 'none');
h4 = plot(ax2, nan, nan, 'LineStyle', 'none', 'Color', [0.0 0.35 0.90]);

lgd = legend(ax2, [h1 h2 h3 h4], ...
    {'Essential HO (Valid)', 'Wasted HO (UHO)', 'Wasted HO (HOPP)', 'Blue text: Wasted ratio (%)'}, ...
    'Location', 'northeast');
lgd.Box = 'on';

hold(ax2, 'off');

savefig(fullfile(resultsDir, 'Fig2_HOEfficiency_main4.fig'));
saveas(gcf, fullfile(resultsDir, 'Fig2_HOEfficiency_main4.png'));

%% =======================================================================
% Fig3: Reliability main4
%   wasted HO ratio + Short ToS ratio
%   하나의 그래프, dual y-axis, bar graph
% ========================================================================
figure('Name', 'Fig3_Reliability_main4', 'Color', 'w');

x = 1:numel(idxMain);

yyaxis left;
bWaste = bar(x - 0.17, mWastedProb(idxMain), 0.34, ...
    'FaceColor', [0.85 0.33 0.10], ...
    'EdgeColor', [0.55 0.18 0.05], ...
    'FaceAlpha', 0.82);
ylabel('Wasted HO ratio [%]');
ax3 = gca;
ax3.YAxis(1).Color = [0.85 0.33 0.10];

validWaste = mWastedProb(idxMain);
validWaste = validWaste(~isnan(validWaste));
if isempty(validWaste)
    ylim([0 1]);
else
    ylim([0 max(validWaste)*1.25]);
end

yoffWaste = 0.03 * max([validWaste(:); 1]);
for i = 1:numel(idxMain)
    yv = mWastedProb(idxMain(i));
    if ~isnan(yv)
        text(x(i)-0.17, yv + yoffWaste, sprintf('%.1f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', [0.55 0.18 0.05]);
    end
end

yyaxis right;
bSTS = bar(x + 0.17, mShortToSProb(idxMain), 0.34, ...
    'FaceColor', [0.12 0.55 0.20], ...
    'EdgeColor', [0.08 0.35 0.12], ...
    'FaceAlpha', 0.78);
ylabel('Short ToS ratio [%]');
ax3.YAxis(2).Color = [0.12 0.55 0.20];

validSTS = mShortToSProb(idxMain);
validSTS = validSTS(~isnan(validSTS));
if isempty(validSTS)
    ylim([0 1]);
else
    ylim([0 max(validSTS)*1.25]);
end

yoffSTS = 0.03 * max([validSTS(:); 1]);
for i = 1:numel(idxMain)
    yv = mShortToSProb(idxMain(i));
    if ~isnan(yv)
        text(x(i)+0.17, yv + yoffSTS, sprintf('%.1f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', [0.08 0.35 0.12]);
    end
end

grid on;
set(gca, 'XTick', x, 'XTickLabel', labelsMain, 'XTickLabelRotation', 18);
% title('Reliability Comparison: Wasted HO and Short ToS');
legend([bWaste, bSTS], {'Wasted HO ratio [%]', 'Short ToS ratio [%]'}, 'Location', 'northeast');

savefig(fullfile(resultsDir, 'Fig3_Reliability_main4.fig'));
saveas(gcf, fullfile(resultsDir, 'Fig3_Reliability_main4.png'));

%% =======================================================================
% Fig4: A3T1 timer sensitivity
%   wasted HO ratio(UHO+HOPP) + Average DL SINR
%   하나의 그래프, 둘 다 점+선
% ========================================================================
figure('Name', 'Fig4_TimerSensitivity_A3T1', 'Color', 'w');

x = 1:numel(idxVar);

yyaxis left;
pWasteVar = plot(x, mWastedProb(idxVar), '-o', ...
    'LineWidth', 2.5, ...
    'MarkerSize', 8, ...
    'Color', [0.85 0.33 0.10], ...
    'MarkerFaceColor', [0.85 0.33 0.10]);
ylabel('Wasted HO ratio [%]');
ax4 = gca;
ax4.YAxis(1).Color = [0.85 0.33 0.10];

validWasteVar = mWastedProb(idxVar);
validWasteVar = validWasteVar(~isnan(validWasteVar));
if isempty(validWasteVar)
    ylim([0 1]);
else
    ylim([0 max(validWasteVar)*1.30]);
end

if isempty(validWasteVar)
    yoffW = 0.1;
else
    yoffW = 0.05 * max([validWasteVar(:); 1]);
end

for i = 1:numel(idxVar)
    yv = mWastedProb(idxVar(i));
    if ~isnan(yv)
        text(i, yv + yoffW, sprintf('%.1f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', [0.55 0.18 0.05]);
    end
end

yyaxis right;
pSINR = plot(x, avgSINR(idxVar), '-s', ...
    'LineWidth', 2.5, ...
    'MarkerSize', 7, ...
    'Color', [0.12 0.38 0.80], ...
    'MarkerFaceColor', [0.12 0.38 0.80]);
ylabel('Average DL SINR [dB]');
ax4.YAxis(2).Color = [0.12 0.38 0.80];

validSINR = avgSINR(idxVar);
validSINR = validSINR(~isnan(validSINR));
if isempty(validSINR)
    ylim([0 1]);
else
    ymin = min(validSINR);
    ymax = max(validSINR);
    if abs(ymax - ymin) < 1e-9
        ylim([ymin-1, ymax+1]);
    else
        margin = 0.20 * (ymax - ymin);
        ylim([ymin - margin, ymax + margin]);
    end
end

if isempty(validSINR)
    yoffS = 0.1;
else
    rangeSINR = max(validSINR) - min(validSINR);
    if rangeSINR < 1e-9
        yoffS = 0.05;
    else
        yoffS = 0.06 * rangeSINR;
    end
end

for i = 1:numel(idxVar)
    yv = avgSINR(idxVar(i));
    if ~isnan(yv)
        text(i, yv + yoffS, sprintf('%.2f', yv), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'Color', [0.05 0.22 0.55]);
    end
end

grid on;
set(gca, 'XTick', x, 'XTickLabel', labelsVar, 'XTickLabelRotation', 15);
% title('Timer Sensitivity: Wasted HO Ratio and Average DL SINR');
legend([pWasteVar, pSINR], {'Wasted HO ratio [%]', 'Average DL SINR [dB]'}, 'Location', 'best');

savefig(fullfile(resultsDir, 'Fig4_TimerSensitivity_A3T1.fig'));
saveas(gcf, fullfile(resultsDir, 'Fig4_TimerSensitivity_A3T1.png'));

%% ===== Console summary =====
disp('================ Final Focused Figure Summary ================');
summaryTable = table(labels(:), mMIT(:), mRBsPerHO(:), mWastedProb(:), mShortToSProb(:), avgSINR(:), ...
    'VariableNames', {'Strategy','MIT_ms','RBs_per_HO','WastedHO_ratio_pct','ShortToS_pct','AvgDL_SINR_dB'});
disp(summaryTable);

disp('Generated figures:');
disp('  1) Fig1_MIT_RBs_main4');
disp('  2) Fig2_HOEfficiency_main4');
disp('  3) Fig3_Reliability_main4');
disp('  4) Fig4_TimerSensitivity_A3T1');

%% ===== Helper functions =====
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