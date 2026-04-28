function plot_results_from_excel()
% Plot 3 figures from results.xlsx (multi-sheet; 1000 UE)
% 1) UHO/HO & HOPP/HO (percent)
% 2) Mean SINR (±std)
% 3) Mean RB  (±std)

clc; close all;

%% ---------------------- Settings ----------------------
% 파일 경로 (둘 중 하나 자동 선택)
cand = {'results.xlsx', fullfile(filesep,'mnt','data','results.xlsx')};
excelFile = '';
for i=1:numel(cand)
    if exist(cand{i},'file'), excelFile = cand{i}; break; end
end
if isempty(excelFile)
    error('results.xlsx 파일을 찾을 수 없습니다. 스크립트와 같은 폴더에 두거나 경로를 수정하세요.');
end

% 출력 폴더(스크립트 폴더 기준)
thisDir = fileparts(mfilename('fullpath'));
outDir  = fullfile(thisDir, 'excel_figs');
if exist(outDir,'file') && ~exist(outDir,'dir')
    error('"%s"는 파일입니다. 삭제/이름변경 후 다시 실행하세요.', outDir);
end
if ~exist(outDir,'dir')
    [ok,msg,msgid] = mkdir(outDir);
    if ~ok, error('폴더 생성 실패: %s (%s)', msg, msgid); end
end

% 전략/속도 표기 및 정렬
strategy_order = {'A3_0','A3_1','TW'};
speed_order    = [50, 100, 200];   % [km/h]

%% ---------------------- Load all sheets ----------------------
[~, sheets] = xlsfinfo(excelFile);
if isempty(sheets), error('시트가 없습니다: %s', excelFile); end

ALL = table(); % Strategy, Speed, HO, UHO, HOPP, SINR_mean, SINR_std, RB_mean, RB_std

for s = 1:numel(sheets)
    Sname = sheets{s};
    T = readtable(excelFile, 'Sheet', Sname, 'PreserveVariableNames', true);

    if isempty(T), continue; end

    % 표준화된 변수명 만들기 (소문자 + 특수문자 제거)
    vn = lower(regexprep(T.Properties.VariableNames, '[^a-z0-9]+', '_'));
    T.Properties.VariableNames = matlab.lang.makeUniqueStrings(vn);

    % 속도 추출: 열에서 찾고 없으면 시트명에서 추론
    spd = tryGetNumeric(T, {'speed','vel','velocity','kmh','km_h','km_per_h'});
    if isempty(spd)
        spd = parseSpeedFromName(Sname); % [50|100|200] 중 추출 시도
    end
    if isempty(spd) % 기본값 (못 찾으면)
        spd = nan(size(T,1),1);
    end

    % ===== 1) 와이드 포맷 감지: A3_0_HO, A3_1_SINR 같은 열이 있는가? =====
    pat = '^(a3_0|a3_1|tw)_(ho|uho|hopp|sinr|rb)$';
    isWide = any(~cellfun('isempty', regexp(T.Properties.VariableNames, pat, 'once')));

    if isWide
        % 전략-지표 조합 추출
        vnames = T.Properties.VariableNames;
        tokens = regexp(vnames, pat, 'tokens', 'once'); % { {strategy}{metric} } or []
        pairs  = vnames(~cellfun('isempty', tokens));
        if isempty(pairs), continue; end

        % 각 전략에 대해 행 생성 (여러 행이면 합/평균)
        S_found = unique(cellfun(@(tk) tk{1}, tokens(~cellfun('isempty',tokens)), 'UniformOutput', false),'stable');

        for k = 1:numel(S_found)
            sname = canonStrategy(S_found{k});
            % 지표별 열 찾기
            ho_col   = findVar(T, sprintf('%s_ho',   lower(sname)));
            uho_col  = findVar(T, sprintf('%s_uho',  lower(sname)));
            hopp_col = findVar(T, sprintf('%s_hopp', lower(sname)));
            sinr_col = findVar(T, sprintf('%s_sinr', lower(sname)));
            rb_col   = findVar(T, sprintf('%s_rb',   lower(sname)));

            % 합/평균/표준편차 계산
            HO   = safeSum(T, ho_col);
            UHO  = safeSum(T, uho_col);
            HOPP = safeSum(T, hopp_col);
            [SINR_m, SINR_s] = safeMeanStd(T, sinr_col);
            [RB_m,   RB_s  ] = safeMeanStd(T, rb_col);

            % 속도: 벡터면 대표값(모드/평균)으로
            spd_k = spd;
            if numel(spd_k) > 1, spd_k = nanmean(spd_k); end

            ALL = [ALL; table({sname}, double(spd_k), HO, UHO, HOPP, SINR_m, SINR_s, RB_m, RB_s, ...
                'VariableNames', {'Strategy','Speed','HO','UHO','HOPP','SINR_mean','SINR_std','RB_mean','RB_std'})]; %#ok<AGROW>
        end

    else
        % ===== 2) 롱 포맷: Strategy/Speed/HO/UHO/HOPP/SINR/RB 열이 존재 =====
        Strategy = tryGetString(T, {'strategy','scheme','algo','method','policy','name'});
        if isempty(Strategy)
            % 시트명에서 전략 추정 (A3_0/A3_1/TW 포함 여부)
            Strategy = repmat({parseStrategyFromName(Sname)}, size(T,1), 1);
        end

        HO_col   = findVar(T, {'ho','ho_attempt','hoattempt','total_ho','num_ho'});
        UHO_col  = findVar(T, {'uho'});
        HOPP_col = findVar(T, {'hopp','pp','pp_count','hopp_count'});
        SINR_col = findVar(T, {'sinr','dl_sinr'});
        RB_col   = findVar(T, {'rb','rbs','rb_usage','avg_rb'});
        
        % 전략별 집계
        G = findgroups(Strategy, num2cell(spd));
        HO   = splitapply(@safeSumVec,   getCol(T,HO_col),   G);
        UHO  = splitapply(@safeSumVec,   getCol(T,UHO_col),  G);
        HOPP = splitapply(@safeSumVec,   getCol(T,HOPP_col), G);
        SINR_m = splitapply(@safeMeanVec, getCol(T,SINR_col), G);
        SINR_s = splitapply(@safeStdVec,  getCol(T,SINR_col), G);
        RB_m   = splitapply(@safeMeanVec, getCol(T,RB_col),   G);
        RB_s   = splitapply(@safeStdVec,  getCol(T,RB_col),   G);

        S_grp = splitapply(@(x)x(1), Strategy, G);
        V_grp = splitapply(@(x)nanmean(x), spd, G);

        tmp = table(canonStrategy(S_grp), double(V_grp), HO, UHO, HOPP, SINR_m, SINR_s, RB_m, RB_s, ...
            'VariableNames', {'Strategy','Speed','HO','UHO','HOPP','SINR_mean','SINR_std','RB_mean','RB_std'});
        ALL = [ALL; tmp]; %#ok<AGROW>
    end
end

% 정리: 전략/속도 필터 및 순서
ALL.Strategy = categorical(ALL.Strategy, strategy_order, 'Ordinal', true);
ALL.Speed    = round(ALL.Speed);
ALL = ALL(ismember(ALL.Strategy, strategy_order)' & ismember(ALL.Speed, speed_order), :);

% 중복 그룹(동일 전략/속도)이면 다시 합치기(여러 시트에서 들어왔다면)
G = findgroups(ALL.Strategy, ALL.Speed);
ALL2 = varfun(@nansum, ALL, 'InputVariables', {'HO','UHO','HOPP'}, 'GroupingVariables', {'Strategy','Speed'});
SINR_m = splitapply(@nanmean, ALL.SINR_mean, G);
SINR_s = splitapply(@nanmean, ALL.SINR_std,  G);
RB_m   = splitapply(@nanmean, ALL.RB_mean,   G);
RB_s   = splitapply(@nanmean, ALL.RB_std,    G);

ALL2.SINR_mean = SINR_m;
ALL2.SINR_std  = SINR_s;
ALL2.RB_mean   = RB_m;
ALL2.RB_std    = RB_s;

% 비율 계산 (%)
ALL2.UHO_per_HO  = 100 * ALL2.nansum_UHO  ./ max(ALL2.nansum_HO,  eps);
ALL2.HOPP_per_HO = 100 * ALL2.nansum_HPPP ./ max(ALL2.nansum_HO,  eps);

% 보기 좋게 변수명 변경
ALL2.Properties.VariableNames(contains(ALL2.Properties.VariableNames,'nansum_')) = ...
    strrep(ALL2.Properties.VariableNames(contains(ALL2.Properties.VariableNames,'nansum_')), 'nansum_', '');

% 전략×속도 매트릭스로 변환
[Svals, Speeds] = ndgrid(categories(ALL2.Strategy), speed_order);
M = @(col) pivot(ALL2, 'Strategy', 'Speed', col, strategy_order, speed_order);

Mat_UHO  = M('UHO_per_HO');
Mat_HPPP = M('HOPP_per_HO');
Mat_SINR = M('SINR_mean');  Mat_SINR_std = M('SINR_std');
Mat_RB   = M('RB_mean');    Mat_RB_std   = M('RB_std');

%% ---------------------- Figure 1: UHO/HO & HOPP/HO ----------------------
f1 = figure('Position',[60 60 1200 500],'Color','w');
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');

% 좌: UHO/HO
nexttile; 
b1 = bar(Mat_UHO,'grouped'); hold on; grid on; box on;
title('UHO / HO (%)'); ylabel('%');
xticklabels(strategy_order); set(gca,'FontSize',12);
legend(compose('%dkm/h', speed_order),'Location','northwest');
ylim([0, max([Mat_UHO(:); 0]) * 1.15 + 1]);

% 우: HOPP/HO
nexttile;
b2 = bar(Mat_HPPP,'grouped'); hold on; grid on; box on;
title('HOPP / HO (%)'); ylabel('%');
xticklabels(strategy_order); set(gca,'FontSize',12);
legend(compose('%dkm/h', speed_order),'Location','northwest');
ylim([0, max([Mat_HPPP(:); 0]) * 1.15 + 1]);

saveas(f1, fullfile(outDir,'fig1_uho_hopp_ratio.png'));
savefig(f1, fullfile(outDir,'fig1_uho_hopp_ratio.fig'));

%% ---------------------- Figure 2: SINR mean ± std ----------------------
f2 = figure('Position',[80 80 950 600],'Color','w');
b = bar(Mat_SINR,'grouped'); hold on; grid on; box on;
title('Average DL SINR (mean ± std)'); ylabel('dB'); xticklabels(strategy_order);
set(gca,'FontSize',12);
legend(compose('%dkm/h', speed_order),'Location','southoutside','Orientation','horizontal');

% errorbar 위치 잡고 그리기
for j = 1:numel(b)
    x = b(j).XEndPoints;  y = Mat_SINR(:,j);
    e = Mat_SINR_std(:,j);
    errorbar(x, y, e, 'k', 'linestyle','none', 'LineWidth',1);
end

saveas(f2, fullfile(outDir,'fig2_sinr_mean_std.png'));
savefig(f2, fullfile(outDir,'fig2_sinr_mean_std.fig'));

%% ---------------------- Figure 3: RB mean ± std -------------------------
f3 = figure('Position',[90 90 950 600],'Color','w');
b = bar(Mat_RB,'grouped'); hold on; grid on; box on;
title('Average RB usage (mean ± std)'); ylabel('RB'); xticklabels(strategy_order);
set(gca,'FontSize',12);
legend(compose('%dkm/h', speed_order),'Location','southoutside','Orientation','horizontal');

for j = 1:numel(b)
    x = b(j).XEndPoints;  y = Mat_RB(:,j);
    e = Mat_RB_std(:,j);
    errorbar(x, y, e, 'k', 'linestyle','none', 'LineWidth',1);
end

saveas(f3, fullfile(outDir,'fig3_rb_mean_std.png'));
savefig(f3, fullfile(outDir,'fig3_rb_mean_std.fig'));

fprintf('\nSaved figures to: %s\n', outDir);

end % main


%% ========================= Helpers =========================
function s = canonStrategy(s)
% 표기 통일: a3_0, a3-0, A3_0 등 → 'A3_0' / 'A3_1' / 'TW'
if iscellstr(s), s = s(:); end
if isstring(s), s = cellstr(s); end
if ischar(s)
    s0 = lower(regexprep(s,'[^a-z0-9]+',''));
else
    s0 = lower(regexprep(string(s),'[^a-z0-9]+',''));
    s0 = s0{1};
end
if contains(s0,'a30'), s = 'A3_0';
elseif contains(s0,'a31'), s = 'A3_1';
elseif contains(s0,'tw'), s = 'TW';
else, s = upper(s);
end
end

function v = findVar(T, names)
% names: string or cellstr 후보
if ischar(names) || isstring(names), names = {char(names)}; end
v = [];
for i=1:numel(names)
    nm = lower(regexprep(names{i}, '[^a-z0-9]+','_'));
    idx = find(strcmp(T.Properties.VariableNames, nm), 1);
    if ~isempty(idx), v = idx; return; end
end
end

function col = getCol(T, idx)
if isempty(idx), col = nan(height(T),1); return; end
col = T{:,idx};
end

function x = tryGetNumeric(T, names)
if ischar(names) || isstring(names), names = {char(names)}; end
x = [];
for i=1:numel(names)
    idx = findVar(T, names{i});
    if ~isempty(idx)
        xi = T{:,idx};
        xi = double(xi);
        x  = xi;
        return;
    end
end
end

function s = tryGetString(T, names)
if ischar(names) || isstring(names), names = {char(names)}; end
s = [];
for i=1:numel(names)
    idx = findVar(T, names{i});
    if ~isempty(idx)
        si = T{:,idx};
        if isstring(si) || iscellstr(si)
            s = si;
        else
            s = string(si);
        end
        return;
    end
end
end

function spd = parseSpeedFromName(Sname)
spd = [];
tok = regexp(Sname,'(50|100|200)\s*km/?h?','tokens','once','ignorecase');
if isempty(tok)
    tok = regexp(Sname,'(?:^|[^0-9])(50|100|200)(?:[^0-9]|$)','tokens','once');
end
if ~isempty(tok)
    spd = str2double(tok{1});
end
end

function st = parseStrategyFromName(Sname)
sn = lower(regexprep(Sname,'[^a-z0-9]+',''));
if contains(sn,'a30'), st = 'A3_0';
elseif contains(sn,'a31'), st = 'A3_1';
elseif contains(sn,'tw'),  st = 'TW';
else, st = 'TW'; % default
end
end

function y = safeSum(T, col)
if isempty(col), y = 0; else, y = nansum(T{:,col}(:)); end
end
function [m,s] = safeMeanStd(T, col)
if isempty(col), m = NaN; s = NaN; return; end
v = T{:,col};
m = nanmean(v(:)); s = nanstd(v(:),0);
end
function y = safeSumVec(x),    y = nansum(x); end
function y = safeMeanVec(x),   y = nanmean(x); end
function y = safeStdVec(x),    y = nanstd(x,0); end

function M = pivot(T, rowKey, colKey, valName, rowOrder, colOrder)
% T: table with GroupingVariables {rowKey, colKey} and valName
% rowOrder/colOrder define ordering
R = categories(categorical(T.(rowKey), rowOrder, 'Ordinal',true));
C = colOrder;
M = nan(numel(R), numel(C));
for i=1:numel(R)
    for j=1:numel(C)
        ix = T.(rowKey)==R{i} & T.(colKey)==C(j);
        v = T{ix, valName};
        if ~isempty(v)
            M(i,j) = v(1);
        end
    end
end
end
