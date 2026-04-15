clear;
close all;

%% =======================================
% 설정 확인 필수
UE_num = 2000;

START_TIME = 0;
SAMPLE_TIME = 0.2; % 200ms 간격
TOTAL_TIME = 173.21 / 7.56; % 동적으로 계산된 총 시뮬레이션 시간
STOP_TIME = TOTAL_TIME;
TIMEVECTOR = START_TIME:SAMPLE_TIME:STOP_TIME; % 동적으로 시간 벡터 생성
expected_samples = length(TIMEVECTOR); % 예상되는 시간 스텝 개수
% =======================================

% 데이터 경로 관련
cases = 'case 1';
case_path = 'MasterResults\250401';

% 결과 저장 폴더 설정
output_folder = '_MASTER_RESULTS_FIGURE_';

% 폴더가 없으면 생성
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% strategies_all = {'Strategy A', 'Strategy B', 'Strategy D', 'Strategy F', 'Strategy I', 'Strategy J', 'Strategy K', 'Strategy L'};
strategies_all = {'Strategy A', 'Strategy B', 'Strategy C', 'Strategy D', 'Strategy E', 'Strategy F', 'Strategy G', 'Strategy H'};
subset_indices = [1, 4, 7, 8, 9];  % A, D, G, J, K
% scenarios = {'DenseUrban', 'Rural'};
scenarios = {'Rural'};

% 색상 설정
display_names = {'Set 1', 'Set 2', 'Set 3', 'Set 4', 'Set 5', 'Set 6', 'Set 7', 'Set 8'}; 
colors_all = { ...
    [0, 0.447, 0.741], [0, 0.447, 0.741], [0, 0.447, 0.741], [0, 0.447, 0.741], [0, 0.447, 0.741] ...
    [0.85, 0.325, 0.098], [0.635, 0.078, 0.184], [0.635 0.078 0.184], [0.494, 0.184, 0.556]};

lineStyles_all = {'--',':','--','--','--','-.', '-.', '-.', '-'};
markerStyles_all = {'o', 'v', '^', 'square', 'diamond', 'pentagram', 'hexagram', 'x'};

% 부드러운 색상 설정
bar1_colors = [0, 0.447, 0.7410];  % 파란색
bar2_colors = [0.635, 0.078, 0.184];  % 빨간색
bar3_colors = [0.4940 0.1840 0.5560];  % 보라색

% Initialize data containers
raw_sinr_data_all = cell(length(scenarios), length(strategies_all));
raw_rsrp_data_all = cell(length(scenarios), length(strategies_all));
sinr_data_all = cell(length(scenarios), length(strategies_all));
rsrp_data_all = cell(length(scenarios), length(strategies_all));
rlf_data_all = cell(length(scenarios), length(strategies_all));
uho_data_all = cell(length(scenarios), length(strategies_all));
ho_data_all = cell(length(scenarios), length(strategies_all));
uho_ho_ratio_all = cell(length(scenarios), length(strategies_all));
sub_tos_data_all = cell(length(scenarios), length(subset_indices));
tos_data_all = cell(length(scenarios), length(strategies_all));
hopp_data_all = cell(length(scenarios), length(strategies_all));
rbs_data_all = cell(length(scenarios), length(strategies_all));

% Load data for each strategy and scenario
for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        % Corrected path using filesep
        data_path = fullfile(case_path, [cases, '_MASTER_RESULTS_', strategies_all{i}, '_', scenarios{s}, '.mat']);
        
        % Check if the file exists before attempting to load
        if exist(data_path, 'file') == 2
            loaded_data = load(data_path, 'MASTER_RAW_SINR', 'MASTER_RAW_RSRP', 'MASTER_UHO', 'MASTER_HO', 'MASTER_RLF', 'MASTER_SINR', 'MASTER_RSRP', 'MASTER_ToS', 'MASTER_HOPP', 'MASTER_RBs');
            
            raw_sinr_data_all{s, i} = loaded_data.MASTER_RAW_SINR(:);
            sinr_data_all{s, i} = loaded_data.MASTER_SINR(:);
            raw_rsrp_data_all{s, i} = loaded_data.MASTER_RAW_RSRP(:);
            rsrp_data_all{s, i} = loaded_data.MASTER_RSRP(:);
            uho_data_all{s, i} = mean(loaded_data.MASTER_UHO, 1);
            ho_data_all{s, i} = mean(loaded_data.MASTER_HO, 1);
            rlf_data_all{s, i} = sum(loaded_data.MASTER_RLF, 1);
            hopp_data_all{s, i} = mean(loaded_data.MASTER_HOPP, 1);
            rbs_data_all{s, i} = mean(loaded_data.MASTER_RBs, 1);
            
            % Calculate UHO/HO ratio
            uho_ho_ratio_all{s, i} = uho_data_all{s, i} ./ (ho_data_all{s, i} + eps);
            
            % Load ToS data only for the subset strategies
            if ismember(i, subset_indices) && isfield(loaded_data, 'MASTER_ToS')
                sub_tos_data_all{s, i == subset_indices} = loaded_data.MASTER_ToS(:);
            end
            
            % Load ToS data for all strategies
            if isfield(loaded_data, 'MASTER_ToS')
                tos_data_all{s, i} = loaded_data.MASTER_ToS(:);
            end
        else
            warning('File %s does not exist.', data_path);
        end
    end
end

total_rb_per_ue_all = zeros(length(strategies_all), length(scenarios));  % 각 전략과 시나리오별로 단말당 사용된 RB 계산
for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        ho_data = ho_data_all{s, i};  % 해당 시나리오의 HO 횟수 데이터
        total_rb_per_ue_all(i, s) = sum(ho_data * 10) / UE_num;  % 각 전략에서 단말당 평균 사용된 RB 계산
    end
end

% 각 전략과 시나리오별로 HO당 발생한 HOPP 비율 계산
hopp_per_ho_all = zeros(length(strategies_all), length(scenarios));  % 각 전략과 시나리오별로 HO당 HOPP 발생률 계산

for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        ho_data = ho_data_all{s, i};  % 해당 시나리오의 HO 횟수 데이터
        hopp_data = hopp_data_all{s, i};  % 해당 시나리오의 HOPP 데이터
        total_ho = sum(ho_data);  % 전체 HO 횟수 계산
        total_hopp = sum(hopp_data);  % 전체 HOPP 횟수 계산

        % HO당 HOPP 비율 계산
        hopp_per_ho_all(i, s) = (total_hopp / total_ho) * 100;  % HO당 HOPP 비율 (%)로 계산
    end
end

% Load HOPP Data for Each Strategy and Scenario
hopp_data_all = cell(length(scenarios), length(strategies_all));

for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        % Load the MASTER_HOPP data from the existing MAT file
        data_path = fullfile(case_path, [cases, '_MASTER_RESULTS_', strategies_all{i}, '_', scenarios{s}, '.mat']);
        
        % Check if the file exists before attempting to load
        if exist(data_path, 'file') == 2
            loaded_data = load(data_path, 'MASTER_HOPP');
            hopp_data_all{s, i} = mean(loaded_data.MASTER_HOPP, 1);  % 평균 HOPP 값을 저장
        else
            warning('File %s does not exist.', data_path);
        end
    end
end

% Calculate UHO per HO and HOPP per UHO for both DenseUrban and Rural scenarios
uho_per_ho_all = zeros(length(strategies_all), length(scenarios));  % Initialize UHO per HO
hopp_per_ho_all = zeros(length(strategies_all), length(scenarios));  % Initialize HOPP per UHO

for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        % UHO per HO 계산
        ho_data = ho_data_all{s, i};  % HO data for the current scenario and strategy
        uho_data = uho_data_all{s, i};  % UHO data
        total_ho = sum(ho_data);  % Total HO count
        total_uho = sum(uho_data);  % Total UHO count
        
        % UHO per HO 비율 계산
        if total_ho > 0  % HO가 존재할 때만 계산
            uho_per_ho_all(i, s) = (total_uho / total_ho) * 100;  % UHO per HO as a percentage
            % uho_per_ho_all(i, s) = round((total_uho / TOTAL_TIME) / UE_num, 2);  % UHO per HO as a percentage
        else
            uho_per_ho_all(i, s) = 0;  % HO가 없으면 0으로 설정
        end
        
        % HOPP per UHO 계산
        total_hopp = sum(hopp_data_all{s, i});  % Total HOPP count
        
        % UHO가 존재할 때만 HOPP per UHO 계산
        if total_uho > 0 && total_hopp > 0  % UHO와 HOPP가 모두 존재할 때만 계산
            hopp_per_ho_all(i, s) = (total_hopp / total_ho) * 100;  % HOPP per UHO as percentage
            % hopp_per_ho_all(i, s) = round((total_hopp / total_sim_time) / UE_num, 2);  % HOPP per UHO as percentage
        else
            hopp_per_ho_all(i, s) = 0;  % UHO 또는 HOPP가 없으면 0으로 설정
        end
        
        % 디버그 정보 출력: HOPP와 UHO 데이터 확인
        fprintf('Strategy: %s, Scenario: %s, total_ho: %d, total_uho: %d, total_hopp: %d\n', ...
                strategies_all{i}, scenarios{s}, total_ho, total_uho, total_hopp);
    end
end

% 반올림
raw_sinr_data_all = cellfun(@(x) round(x, 3), raw_sinr_data_all, 'UniformOutput', false);
sinr_data_all = cellfun(@(x) round(x, 3), sinr_data_all, 'UniformOutput', false);
raw_rsrp_data_all = cellfun(@(x) round(x, 3), raw_rsrp_data_all, 'UniformOutput', false);
rsrp_data_all = cellfun(@(x) round(x, 3), rsrp_data_all, 'UniformOutput', false);
uho_data_all = cellfun(@(x) round(x, 3), uho_data_all, 'UniformOutput', false);
ho_data_all = cellfun(@(x) round(x, 3), ho_data_all, 'UniformOutput', false);
rlf_data_all = cellfun(@(x) round(x, 3), rlf_data_all, 'UniformOutput', false);
hopp_data_all = cellfun(@(x) round(x, 3), hopp_data_all, 'UniformOutput', false);
uho_ho_ratio_all = cellfun(@(x) round(x, 3), uho_ho_ratio_all, 'UniformOutput', false);
sub_tos_data_all = cellfun(@(x) round(x, 3), sub_tos_data_all, 'UniformOutput', false);
tos_data_all = cellfun(@(x) round(x, 3), tos_data_all, 'UniformOutput', false);
hopp_per_ho_all = round(hopp_per_ho_all, 3);
uho_per_ho_all = round(uho_per_ho_all, 3);

% 각 bar의 색상을 개별 설정 적용하기
% Plot: 초당 단말당 RLF, UHO/HO, HOPP/HO, UHO per HO & HOPP per UHO, SINR Box Plot, SINR CDF, RBs, ToS
% 각 figure의 subplot을 독립적으로 저장하도록 수정

%% --------------------------------------------------------------------------------------------------------------------
% FIGURE CODE
% RLF, UHO, ToS, RSRP, SINR, RBs, HOPP, SHORTTOS, etc
% --------------------------------------------------------------------------------------------------------------------

%% [SCI MAIN FIGURE] RLF (Rural Only 버전, Set별 색상 적용)
figure('Position', [100, 100, 1000, 800]);

% 📌 평균 RLF 계산 (초당 단말당 RLF 횟수) - Rural만 사용
average_rlf_per_sec = zeros(length(strategies_all), 1);  % 전략 개수만큼 1열

for i = 1:length(strategies_all)
    average_rlf_per_sec(i) = mean(rlf_data_all{1, i});  % Rural
end

% 🎨 Set별 색상 정의
rural_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];

% 📊 막대 그래프 (Rural만)
b = bar(average_rlf_per_sec, 'FaceColor', 'flat');
b.CData = rural_colors;

% 🧭 축 및 라벨 설정
set(gca, 'XTick', 1:length(strategies_all), 'XTickLabel', display_names, 'FontSize', 17.5);
ylabel('Average RLF [#operations/UE]', 'FontSize', 17.5);
ylim([0, max(average_rlf_per_sec) + 0.05]);
grid on; grid minor;

% ✅ 막대 위에 수치 표시
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = average_rlf_per_sec(i);
    text(xt(i), value + 0.005, sprintf('%.2f', value), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 12);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_rlf_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_rlf_rural_only_coloredBySet.png'));



%% [SCI MAIN FIGURE] UHO/HO (Rural Only + Set별 색상 적용)
figure('Position', [100, 100, 1000, 800]);

% 🌾 Rural 데이터만 추출
uho_per_ho_rural = uho_per_ho_all(:, 1);  % Rural만 사용 (col 1)

% 🎨 Set별 색상 정의
rural_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];

% 📊 막대 그래프
b = bar(uho_per_ho_rural, 'FaceColor', 'flat');
b.CData = rural_colors;

% 🧭 축 및 라벨 설정
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
ylabel('UHO/HO ratio (%)', 'FontSize', 17.5);
ylim([0, max(uho_per_ho_rural) + 5]);
grid on; grid minor;

% ✅ 막대 위에 수치 표기
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = uho_per_ho_rural(i);
    x = xt(i);  % 단일 막대 중심
    y = value + 0.5;
    text(x, y, sprintf('%d', round(value)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_uho_per_ho_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_uho_per_ho_rural_only_coloredBySet.png'));


%% [SCI MAIN FIGURE] HOPP/HO (Rural Only + Set별 색상 적용)
figure('Position', [100, 100, 1000, 800]);

% 🌾 Rural 데이터만 추출
hopp_per_ho_rural = hopp_per_ho_all(:, 1);  % Rural만 사용 (col 1)

% 🎨 Set별 색상 정의
rural_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];

% 📊 막대 그래프
b = bar(hopp_per_ho_rural, 'FaceColor', 'flat');
b.CData = rural_colors;

% 🧭 축 및 라벨 설정
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
ylabel('PP/HO ratio (%)', 'FontSize', 17.5);
ylim([0, max(hopp_per_ho_rural) + 5]);
grid on; grid minor;

% ✅ 막대 위에 수치 표기
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = hopp_per_ho_rural(i);
    x = xt(i);
    y = value + 0.5;
    text(x, y, sprintf('%d', round(value)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_hopp_per_ho_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_hopp_per_ho_rural_only_coloredBySet.png'));


%% [SCI MAIN FIGURE] Combined UHO & HOPP (Rural Only, Dual Y-Axis)

figure('Position', [180, 180, 1080, 880]);

% 🌾 Rural 데이터만 추출
uho_rural = uho_per_ho_all(:, 1);    % UHO/HO (%)
hopp_rural = hopp_per_ho_all(:, 1);  % HOPP/HO (%)

% 🎨 색상 정의 (UHO: 진한색, HOPP: 연한색)
uho_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];
hopp_colors = uho_colors * 0.6 + 0.4;  % 동일한 계열의 연한 색상

% 🧱 막대 폭과 간격 설정
bar_width = 0.4;

% 🎨 UHO - 왼쪽 y축
yyaxis left;
b1 = bar((1:length(uho_rural)) - bar_width/2, uho_rural, bar_width, 'FaceColor', 'flat');
b1.CData = uho_colors;
ylabel('UHO/HO ratio (%)', 'FontSize', 17.5);
ylim([0, 20]);

% 🎨 HOPP - 오른쪽 y축
yyaxis right;
b2 = bar((1:length(hopp_rural)) + bar_width/2, hopp_rural, bar_width, 'FaceColor', 'flat');
b2.CData = hopp_colors;
ylabel('HOPP/HO ratio (%)', 'FontSize', 17.5);
ylim([0, 20]);

% 🧭 공통 x축
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
xtickangle(0);
grid on; grid minor;

% 🏷️ 제목
% title('UHO and HOPP Ratios per HO (Rural Only)', 'FontSize', 18);

% ✅ 수치 표기 (UHO - 왼쪽)
yyaxis left;
xt = get(gca, 'XTick');
for i = 1:length(uho_rural)
    x = xt(i) - bar_width/2;
    y = uho_rural(i) + 0.5;
    text(x, y, sprintf('%d', round(uho_rural(i))), ...
        'HorizontalAlignment', 'center', 'FontSize', 13);
end

% ✅ 수치 표기 (HOPP - 오른쪽)
yyaxis right;
for i = 1:length(hopp_rural)
    x = xt(i) + bar_width/2;
    y = hopp_rural(i) + 0.5;
    text(x, y, sprintf('%d', round(hopp_rural(i))), ...
        'HorizontalAlignment', 'center', 'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_uho_hopp_per_ho_rural_combined_dualy.fig'));
saveas(gcf, fullfile(output_folder, 'compare_uho_hopp_per_ho_rural_combined_dualy.png'));



%% --------------------------------------------------------------------------------------------------------------------

%% [SCI MAIN FIGURE] Average SINR (Rural Only + Set별 색상 적용)
figure('Position', [100, 100, 1000, 850]);

% 데이터 준비
sinr_data_per_strategy_rural = [];
group_rural = [];

for i = 1:length(display_names)
    current_data = round(sinr_data_all{1, i}, 3);  % 소수점 3자리 반올림
    sinr_data_per_strategy_rural = [sinr_data_per_strategy_rural; current_data];  
    group_rural = [group_rural; i * ones(length(current_data), 1)];
end

% 색상 설정 (Set 1~4: 진한 남색 / Set 5~7: 진한 갈색 / Set 8: 진한 붉은색)
box_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 갈색
    [0.6, 0, 0]                      % Set 8: 붉은색
];

% boxplot 그리기
boxplot(sinr_data_per_strategy_rural, group_rural, 'Labels', display_names, 'Colors', 'k');

% Box 색상 덮어씌우기
h = findobj(gca, 'Tag', 'Box');
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), box_colors(length(h)-j+1,:), 'FaceAlpha', 0.3);
    % 중앙값 선을 검정색으로 진하게 설정
    h_median = findobj(gca, 'Tag', 'Median');
    set(h_median, 'Color', 'k', 'LineWidth', 1.8);  % 중앙값 선 두껍게
end

% 라벨 설정
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
set(gca, 'XTickLabel', display_names, 'FontSize', 17.5);
grid on;
grid minor;

% 저장
savefig(fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.png'));

%% AVERAGE SINR - new 바이올린 플롯으로 유력한 MAIN
figure('Position', [70, 70, 930, 730]);
hold on;

% 색상 정의 (Set 1~4: 남색 / Set 5~7: 갈색 / Set 8: 붉은색)
box_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 갈색
    [0.6, 0, 0]                      % Set 8: 붉은색
];

% 평균/중앙값 마커 저장용
mean_handles = gobjects(1,1);
median_handles = gobjects(1,1);

for i = 1:length(display_names)
    y_data = round(sinr_data_all{1, i}, 3);
    
    % 분포 곡선
    [f, xi] = ksdensity(y_data);
    f = f / max(f) * 0.3;  % 정규화 후 너비 조절
    fill([i - f, fliplr(i + f)], [xi, fliplr(xi)], box_colors(i, :), ...
        'FaceAlpha', 0.35, 'EdgeColor', 'none');

    % 중앙값 (점선)
    median_val = median(y_data);
    median_handles = plot([i - 0.2, i + 0.2], [median_val, median_val], ...
        'k:', 'LineWidth', 2.0);  % 점선으로 표기

    % 평균 (빈 원)
    mean_val = mean(y_data);
    mean_handles = plot(i, mean_val, 'ko', 'MarkerSize', 7, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');
end

xlim([0.5, length(display_names) + 0.5]);
ylim([-5.3, 0.6]);
xticks(1:length(display_names));
xticklabels(display_names);
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
% title('DL SINR Distribution with Median and Mean (Rural)', 'FontSize', 17);
set(gca, 'FontSize', 15);
grid on; grid minor;

% 범례 추가
legend([median_handles, mean_handles], {'Median value', 'Mean value'}, ...
    'Location', 'southwest', 'FontSize', 13);

% 저장
savefig(fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.fig'));
saveas(gcf, fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.png'));



%% AVG SINR CUSTOM HISTOGRAM
figure('Position', [100, 100, 1000, 850]);
hold on;

for i = 1:length(display_names)
    y_data = sinr_data_all{1, i};
    x_jitter = (rand(size(y_data)) - 0.5) * 0.6;  % x축 jitter 추가
    x_pos = i + x_jitter;

    % 점 분포 (색상 적용)
    scatter(x_pos, y_data, 10, ...
        'MarkerEdgeAlpha', 0.3, ...
        'MarkerFaceAlpha', 0.3, ...
        'MarkerFaceColor', box_colors(i,:), ...
        'MarkerEdgeColor', box_colors(i,:));

    % 중앙값 점선
    median_val = median(y_data);
    plot([i - 0.25, i + 0.25], [median_val, median_val], ...
        'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.8);

    % 평균값 빈 원 마커
    mean_val = mean(y_data);
    plot(i, mean_val, 'ko', 'MarkerSize', 7, 'LineWidth', 1.6);  % 빈 원
end

% 라벨 및 축 설정
set(gca, 'XTick', 1:length(display_names), 'XTickLabel', display_names, 'FontSize', 17.5);
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
ylim([-4.5, -0.3]);
grid on; grid minor;
title('DL SINR Distribution per Strategy (Rural)', 'FontSize', 18);

% 🔍 범례 추가 (중앙값과 평균 구분)
h_median = plot(NaN, NaN, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.8);  % 중앙값 점선
h_mean = plot(NaN, NaN, 'ko', 'MarkerSize', 7, 'LineWidth', 1.6);          % 평균 빈 원
legend([h_median, h_mean], {'Median', 'Mean'}, 'FontSize', 14, 'Location', 'southwest');

% 저장
savefig(fullfile(output_folder, 'results_DLSINR_distribution_strip_rural.fig'));
saveas(gcf, fullfile(output_folder, 'results_DLSINR_distribution_strip_rural.png'));




%% SINR CDF plot
figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    sinr_data = raw_sinr_data_all{1, i};
    if ~isempty(sinr_data) && isvector(sinr_data)
        sinr_data_rounded = round(sinr_data, 3);  % SINR 데이터 소수점 3자리 반올림
        [cdf_sinr, x_sinr] = ecdf(sinr_data_rounded);
        plot(x_sinr, cdf_sinr, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, 'LineWidth', 1.5, ...
            'DisplayName', display_names{i});
    else
        warning('SINR data for strategy %s in DenseUrban is either empty or not valid.', strategies_all{i});
    end
end
hold off;
xlabel('DL SINR [dB]', 'FontSize', 17.5);
ylabel('Cumulative distribution function', 'FontSize', 17.5);
legend_handle = legend('Location', 'northwest');
set(legend_handle, 'FontSize', 17.5);  % legend의 글씨 크기 설정
xlim([-10 5]);
ylim([0 1]);
yticks(0:0.1:1);
grid on;
grid minor;
% 결과를 fig와 png로 저장
savefig(fullfile(output_folder, 'results_DLSINR_cdf.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLSINR_cdf.png'));  % png 저장


%% SINR FIGURE _ AVERAGE SINR FIGURE BAR FIGURE
% ===== SINR 평균값 비교 Bar Plot =====
figure('Position', [100, 100, 1000, 800]);

average_sinr = zeros(length(strategies_all), 2);  % 전략별 x 환경별 (DenseUrban=1, Rural=2)

for s = 1:2  % 1: DenseUrban, 2: Rural
    for i = 1:length(strategies_all)
        sinr_data = sinr_data_all{s, i};
        if ~isempty(sinr_data)
            average_sinr(i, s) = round(mean(sinr_data), 2);  % 평균값 소수점 2자리
        end
    end
end

b = bar(average_sinr, 'grouped');
b(1).FaceColor = [0.7, 0.7, 0.7];  % Rural
b(2).FaceColor = [0, 0, 0.5];      % Urban

set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);

ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
legend({'Rural', 'Urban'}, 'Location', 'northeast');
ylim([min(average_sinr(:)) - 1, max(average_sinr(:)) + 1]);
grid on; grid minor;

% 수치 표기 (막대 위 텍스트)
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    for j = 1:2  % 1: Rural, 2: Urban
        value = average_sinr(i, j);
        x = xt(i) + (j - 1.5) * 0.28;  % 위치 조정
        y = value - 0.05;
        text(x, y, sprintf('%.1f', value), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 13);
    end
end

% 저장
savefig(fullfile(output_folder, 'compare_avg_sinr_rural_vs_urban.fig'));
saveas(gcf, fullfile(output_folder, 'compare_avg_sinr_rural_vs_urban.png'));


%% [NEED FIX -- SCI MAIN FIGURE] SINR FIGURE _ CDF LOW *log term
figure('Position', [100, 100, 1200, 800]);
hold on;

num_sets = length(strategies_all);
base_colors = lines(num_sets);  % 기본 컬러맵
adjusted_colors = base_colors * 0.85;  % 채도 낮추기

for i = 1:num_sets
    % DenseUrban (s = 1)
    sinr_data_urban = raw_sinr_data_all{1, i};
    if ~isempty(sinr_data_urban)
        [f_urban, x_urban] = ecdf(sinr_data_urban);
        semilogy(x_urban, f_urban, '-', ...
            'LineWidth', 1.6, ...
            'Color', adjusted_colors(i, :), ...
            'DisplayName', sprintf('Set %d - DenseUrban', i));
    end

    % Rural (s = 2)
    sinr_data_rural = raw_sinr_data_all{2, i};
    if ~isempty(sinr_data_rural)
        [f_rural, x_rural] = ecdf(sinr_data_rural);
        semilogy(x_rural, f_rural, '--', ...
            'LineWidth', 1.6, ...
            'Color', adjusted_colors(i, :), ...
            'DisplayName', sprintf('Set %d - Rural', i));
    end
end

% 축 설정
xlabel('DL SINR [dB]', 'FontSize', 17.5);
ylabel('CDF', 'FontSize', 17.5);
set(gca, 'YScale', 'log');  % 로그 스케일
xlim([-10, 0]);
ylim([1e-2, 1]);

legend('Location', 'southeast', 'FontSize', 12);
grid on;
grid minor;

% 저장
savefig(fullfile(output_folder, 'results_DLSINR_logCDF_rural_vs_urban.fig'));
saveas(gcf, fullfile(output_folder, 'results_DLSINR_logCDF_rural_vs_urban.png'));


%% RSRP plot
% RSRP Box plot
figure('Position', [100, 100, 1000, 850]);
rsrp_data_per_strategy = [];
group_rsrp = [];
for i = 1:length(display_names)
    current_data = round(rsrp_data_all{1, i}, 3);  % 소수점 3자리 반올림
    rsrp_data_per_strategy = [rsrp_data_per_strategy; current_data];  
    group_rsrp = [group_rsrp; i * ones(length(current_data), 1)]; 
end
boxplot(rsrp_data_per_strategy, group_rsrp, 'Labels', display_names);
ylabel('Average DL RSRP [dBm]', 'FontSize', 17.5);
set(gca, 'XTickLabel', display_names, 'FontSize', 17.5);  % X축 FontSize 설정
grid on;
grid minor;
% 결과를 fig와 png로 저장
savefig(fullfile(output_folder, 'results_DLRSPR_box.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLRSPR_box.png'));  % png 저장

% RSRP CDF plot
figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    rsrp_data = raw_rsrp_data_all{1, i};
    if ~isempty(rsrp_data) && isvector(rsrp_data)
        rsrp_data_rounded = round(rsrp_data, 3);  % RSRP 데이터 소수점 3자리 반올림
        [cdf_rsrp, x_rsrp] = ecdf(rsrp_data_rounded);
        plot(x_rsrp, cdf_rsrp, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, 'LineWidth', 1.5, ...
            'DisplayName', display_names{i});
    else
        warning('RSRP data for strategy %s in DenseUrban is either empty or not valid.', strategies_all{i});
    end
end
hold off;
xlabel('DL RSRP [dBm]', 'FontSize', 17.5);
ylabel('Cumulative distribution function', 'FontSize', 17.5);
legend_handle = legend('Location', 'northwest');
set(legend_handle, 'FontSize', 17.5);  % legend의 글씨 크기 설정
% xlim([-120 -60]);
% ylim([0 1]);
% yticks(0:0.1:1);
grid on;
grid minor;
% 결과를 fig와 png로 저장
savefig(fullfile(output_folder, 'results_DLRSPR_cdf.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLRSPR_cdf.png'));  % png 저장

%% RSRP/SINR 시간축 기준 변화 그래프
% RSRP xy 그래프 (시간 vs 평균 RSRP : 전체 전략 한번에 Plot)
figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    rsrp_raw_data = raw_rsrp_data_all{1, i}; % 해당 전략의 RSRP 데이터
    
    if ~isempty(rsrp_raw_data)
        [rows, cols] = size(rsrp_raw_data); % 현재 데이터 크기 확인

        if rows == expected_samples * UE_num && cols == 1
            % 데이터를 115 x UE_num 형태로 변환
            rsrp_raw_data = reshape(rsrp_raw_data, expected_samples, UE_num);
        end
        
        if size(rsrp_raw_data, 1) == expected_samples && size(rsrp_raw_data, 2) == UE_num
            rsrp_mean = mean(rsrp_raw_data, 2);  % 열 방향 평균 (115x1)

            % xy 그래프 플롯
            plot(TIMEVECTOR, rsrp_mean, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, ...
                'LineWidth', 1.5, 'DisplayName', display_names{i});
        else
            warning('RSRP data size mismatch for strategy %s. Expected (%dx%d), but got (%dx%d).', ...
                strategies_all{i}, expected_samples, UE_num, size(rsrp_raw_data, 1), size(rsrp_raw_data, 2));
        end
    else
        warning('RSRP data for strategy %s in DenseUrban is empty.', strategies_all{i});
    end
end

hold off;
xlabel('Time (s)', 'FontSize', 17.5);
ylabel('Average DL RSRP [dBm]', 'FontSize', 17.5);
legend_handle = legend('Location', 'best');
set(legend_handle, 'FontSize', 17.5);  % legend 글씨 크기 설정
grid on;
grid minor;

% 결과 저장
savefig(fullfile(output_folder, 'results_DLRSPR_time.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLRSPR_time.png'));  % png 저장

% RSRP xy 그래프 (시간 vs 평균 RSRP) - 각 전략별 subplot 표시
figure('Position', [100, 100, 1200, 1000]); % 전체 figure 크기 설정
num_strategies = length(strategies_all); % 총 전략 개수
num_rows = ceil(sqrt(num_strategies)); % 서브플롯 행 개수 (정사각형 형태)
num_cols = ceil(num_strategies / num_rows); % 서브플롯 열 개수

for i = 1:num_strategies
    rsrp_raw_data = raw_rsrp_data_all{1, i}; % 해당 전략의 RSRP 데이터
    
    subplot(num_rows, num_cols, i); % 서브플롯 배치
    hold on;
    
    if ~isempty(rsrp_raw_data)
        [rows, cols] = size(rsrp_raw_data); % 현재 데이터 크기 확인

        if rows == expected_samples * UE_num && cols == 1
            % 데이터를 115 x UE_num 형태로 변환
            rsrp_raw_data = reshape(rsrp_raw_data, expected_samples, UE_num);
        end
        
        if size(rsrp_raw_data, 1) == expected_samples && size(rsrp_raw_data, 2) == UE_num
            rsrp_mean = mean(rsrp_raw_data, 2);  % 열 방향 평균 (115x1)

            % xy 그래프 플롯
            plot(TIMEVECTOR, rsrp_mean, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, ...
                'LineWidth', 1.5, 'DisplayName', display_names{i});
            title(display_names{i}, 'FontSize', 12); % 각 subplot에 제목 추가
        else
            warning('RSRP data size mismatch for strategy %s. Expected (%dx%d), but got (%dx%d).', ...
                strategies_all{i}, expected_samples, UE_num, size(rsrp_raw_data, 1), size(rsrp_raw_data, 2));
        end
    else
        warning('RSRP data for strategy %s in DenseUrban is empty.', strategies_all{i});
    end
    
    xlabel('Time (s)', 'FontSize', 10);
    ylabel('Avg DL RSRP [dBm]', 'FontSize', 10);
    ylim([-109 -105]);
    % yticks(0:0.1:1);
    grid on;
    grid minor;
    hold off;
end

% 전체 figure 제목 추가
sgtitle('RSRP Time Evolution for Each Strategy', 'FontSize', 15);

% 결과 저장
savefig(fullfile(output_folder, 'results_DLRSPR_time_subplot.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLRSPR_time_subplot.png'));  % png 저장

%% SINR xy 그래프 (시간 vs 평균 SINR : 전체 전략 한번에 Plot)
figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    sinr_raw_data = raw_sinr_data_all{1, i}; % 해당 전략의 SINR 데이터
    
    if ~isempty(sinr_raw_data)
        [rows, cols] = size(sinr_raw_data); % 현재 데이터 크기 확인

        if rows == expected_samples * UE_num && cols == 1
            % 데이터를 115 x UE_num 형태로 변환
            sinr_raw_data = reshape(sinr_raw_data, expected_samples, UE_num);
        end
        
        if size(sinr_raw_data, 1) == expected_samples && size(sinr_raw_data, 2) == UE_num
            sinr_mean = mean(sinr_raw_data, 2);  % 열 방향 평균 (115x1)

            % xy 그래프 플롯
            plot(TIMEVECTOR, sinr_mean, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, ...
                'LineWidth', 1.5, 'DisplayName', display_names{i});
        else
            warning('SINR data size mismatch for strategy %s. Expected (%dx%d), but got (%dx%d).', ...
                strategies_all{i}, expected_samples, UE_num, size(sinr_raw_data, 1), size(sinr_raw_data, 2));
        end
    else
        warning('SINR data for strategy %s in DenseUrban is empty.', strategies_all{i});
    end
end

hold off;
xlabel('Time (s)', 'FontSize', 17.5);
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
legend_handle = legend('Location', 'best');
set(legend_handle, 'FontSize', 17.5);  % legend 글씨 크기 설정
grid on;
grid minor;

% 결과 저장
savefig(fullfile(output_folder, 'results_DLSINR_time.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLSINR_time.png'));  % png 저장

% SINR xy 그래프 (시간 vs 평균 SINR) - 각 전략별 subplot 표시
figure('Position', [100, 100, 1200, 1000]); % 전체 figure 크기 설정
num_strategies = length(strategies_all); % 총 전략 개수
num_rows = ceil(sqrt(num_strategies)); % 서브플롯 행 개수 (정사각형 형태)
num_cols = ceil(num_strategies / num_rows); % 서브플롯 열 개수

for i = 1:num_strategies
    sinr_raw_data = raw_sinr_data_all{1, i}; % 해당 전략의 SINR 데이터
    
    subplot(num_rows, num_cols, i); % 서브플롯 배치
    hold on;
    
    if ~isempty(sinr_raw_data)
        [rows, cols] = size(sinr_raw_data); % 현재 데이터 크기 확인

        if rows == expected_samples * UE_num && cols == 1
            % 데이터를 115 x UE_num 형태로 변환
            sinr_raw_data = reshape(sinr_raw_data, expected_samples, UE_num);
        end
        
        if size(sinr_raw_data, 1) == expected_samples && size(sinr_raw_data, 2) == UE_num
            sinr_mean = mean(sinr_raw_data, 2);  % 열 방향 평균 (115x1)

            % xy 그래프 플롯
            plot(TIMEVECTOR, sinr_mean, 'Color', colors_all{i}, 'LineStyle', lineStyles_all{i}, ...
                'LineWidth', 1.5, 'DisplayName', display_names{i});
            title(display_names{i}, 'FontSize', 12); % 각 subplot에 제목 추가
        else
            warning('SINR data size mismatch for strategy %s. Expected (%dx%d), but got (%dx%d).', ...
                strategies_all{i}, expected_samples, UE_num, size(sinr_raw_data, 1), size(sinr_raw_data, 2));
        end
    else
        warning('SINR data for strategy %s in DenseUrban is empty.', strategies_all{i});
    end
    
    xlabel('Time (s)', 'FontSize', 10);
    ylabel('Avg DL SINR [dB]', 'FontSize', 10);
    ylim([-6 2]); % SINR 값의 범위를 조정
    grid on;
    grid minor;
    hold off;
end

% 전체 figure 제목 추가
sgtitle('SINR Time Evolution for Each Strategy', 'FontSize', 15);

% 결과 저장
savefig(fullfile(output_folder, 'results_DLSINR_time_subplot.fig'));  % fig 저장
saveas(gcf, fullfile(output_folder, 'results_DLSINR_time_subplot.png'));  % png 저장


%% [SCI MAIN FIGURE] Average RBs (Rural Only + Set별 색상)
figure('Position', [100, 100, 1000, 800]);

% 📌 Rural만 평균 계산
mean_rbs_per_rural = zeros(length(strategies_all), 1);

for i = 1:length(strategies_all)
    avg_hos_times = mean(ho_data_all{1, i}) / TOTAL_TIME;  % 1: Rural
    avg_rbs_time =  mean(rbs_data_all{1, i})/TOTAL_TIME;
    mean_rbs_per_rural(i) = round(avg_hos_times, 2);  % 평균 RBs 사용량 (소수점 2자리)
    % mean_rbs_per_rural(i) = round(avg_hos_times * 10, 2);  % 단말당 초당 사용 RB 수
end

% 🎨 Set별 색상 정의
rural_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];

% 📊 막대 그래프
b = bar(mean_rbs_per_rural, 'FaceColor', 'flat');
b.CData = rural_colors;

% 🧭 축 설정
ylabel('RBs usage [#/UE/sec]', 'FontSize', 17.5);
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
ylim([0, max(mean_rbs_per_rural) + 0.2]);
grid on;
grid minor;

% ✅ 수치 표기
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = mean_rbs_per_rural(i);
    x = xt(i);
    y = value + 0.01;
    text(x, y, sprintf('%.2f', value), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_avgRBs_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_avgRBs_rural_only_coloredBySet.png'));


%% [SCI MAIN FIGURE] TOS FIGURE - CDF 0 to 1 TERM DENSEURBAN AND RURAL
figure('Position', [100, 100, 800, 600]);
hold on;

% 🎯 이상적 구간 시각화: 4.84 ~ 6.61초 (회색 음영)
x_ideal_start = 4.84;
x_ideal_end = 6.61;
y_bottom = 0;
y_top = 1;

fill([x_ideal_start x_ideal_end x_ideal_end x_ideal_start], ...
     [y_bottom y_bottom y_top y_top], ...
     [0.8 0.8 0.8], ...       % 회색
     'EdgeColor', 'none', ...
     'FaceAlpha', 0.3, ...
     'HandleVisibility', 'off');  % 💡 legend에 안 나오게 설정

% 💡 스타일 정의
num_sets = length(strategies_all);
line_styles = {'--', '--', '--', '--', '-.', ':', '--', '-'};
marker_types = {'o', '^', 's', 'd', 'v', '>', '<', 'p'};
legend_names = display_names;
cmap = lines(num_sets);
adjusted_cmap = cmap * 0.85;

% 📈 각 Set의 ToS 데이터로 CDF 곡선 그리기 (DenseUrban만)
for i = 1:num_sets
    tos_data = tos_data_all{1, i};
    if ~isempty(tos_data)
        tos_data = round(tos_data, 3);
        [cdf_vals, x_vals] = ecdf(tos_data);

        plot(x_vals, cdf_vals, ...
            'LineStyle', line_styles{i}, ...
            'Color', adjusted_cmap(i, :), ...
            'LineWidth', 1.6, ...
            'MarkerSize', 6, ...
            'DisplayName', sprintf('%s', legend_names{i}));
    else
        warning('Set %d (DenseUrban) has no ToS data.', i);
    end
end

% 🧭 축 및 기타 설정
xlabel('Time-of-Stay [s]', 'FontSize', 14);
ylabel('CDF', 'FontSize', 14);
xlim([0, 7]);
ylim([0, 1]);
grid on;
legend('Location', 'southeast', 'FontSize', 11);
set(gca, 'FontSize', 13);
set(gcf, 'Color', 'w');

% 💾 저장
savefig(fullfile(output_folder, 'results_ToS_CDF_bySet_DenseUrban_withIdeal.fig'));
saveas(gcf, fullfile(output_folder, 'results_ToS_CDF_bySet_DenseUrban_withIdeal.png'));

%% [SCI MAIN FIGURE2] TOS FIGURE - CDF 0 to 1 TERM DENSEURBAN AND RURAL
figure('Position', [100, 100, 800, 600]);
hold on;

% % 🎯 이상적 구간 시각화: 4.84 ~ 6.61초 (회색 음영)
% x_ideal_start = 4.84;
% x_ideal_end = 6.61;
% y_bottom = 0;
% y_top = 1;
% fill([x_ideal_start x_ideal_end x_ideal_end x_ideal_start], ...
%      [y_bottom y_bottom y_top y_top], ...
%      [0.8 0.8 0.8], ...
%      'EdgeColor', 'none', ...
%      'FaceAlpha', 0.3, ...
%      'HandleVisibility', 'off');  % 🔒 범례에서 제외

% 💡 스타일 정의
num_sets = length(strategies_all);
line_styles = {'--', '--', '--', '--', '-.', ':', '--', '-'};
legend_names = display_names;
cmap = lines(num_sets) * 0.85;

% 📈 메인 플롯
for i = 1:num_sets
    tos_data = tos_data_all{1, i};
    if ~isempty(tos_data)
        tos_data = round(tos_data, 3);
        [cdf_vals, x_vals] = ecdf(tos_data);

        % Set 6만 굵게 강조
        if i == 5
            lw = 2.5;
        else
            lw = 1.6;
        end

        plot(x_vals, cdf_vals, ...
            'LineStyle', line_styles{i}, ...
            'Color', cmap(i, :), ...
            'LineWidth', lw, ...
            'DisplayName', sprintf('%s', legend_names{i}));
    else
        warning('Set %d (DenseUrban) has no ToS data.', i);
    end
end

% 🧭 축 설정
xlabel('Time-of-Stay [s]', 'FontSize', 14);
ylabel('CDF', 'FontSize', 14);
xlim([0, 7]);
ylim([0, 1]);
grid on;
legend('Location', 'southeast', 'FontSize', 11);
set(gca, 'FontSize', 13);
set(gcf, 'Color', 'w');

% 🔍 Inset 확대 그래프
ax_inset = axes('Position', [0.22, 0.60, 0.28, 0.28]);  % 상단 좌측 위치
box on;
hold on;
for i = 1:num_sets
    tos_data = tos_data_all{1, i};
    if ~isempty(tos_data)
        tos_data = round(tos_data, 3);
        [cdf_vals, x_vals] = ecdf(tos_data);

        % 선 굵기 처리 동일
        if i == 6
            lw = 2.5;
        else
            lw = 1.6;
        end

        plot(x_vals, cdf_vals, ...
            'LineStyle', line_styles{i}, ...
            'Color', cmap(i, :), ...
            'LineWidth', lw);
        grid on;
    end
end
xlim([4.7, 5.3]);
ylim([0.5, 0.9]);
set(gca, 'FontSize', 10);
% title('Zoomed View', 'FontSize', 11);

% 💾 저장
savefig(fullfile(output_folder, 'results_ToS_CDF_bySet_DenseUrban_withIdeal_inset.fig'));
saveas(gcf, fullfile(output_folder, 'results_ToS_CDF_bySet_DenseUrban_withIdeal_inset.png'));



%% [SCI MAIN FIGURE] Short ToS (Rural Only + 색상 적용)
figure('Position', [100, 100, 1000, 800]);

% 📌 Rural (s = 1)만 Short ToS 계산
short_tos_ratio_rural = zeros(length(strategies_all), 1);

for i = 1:length(strategies_all)
    tos_data = tos_data_all{1, i};  % 1: Rural
    total_tos_count = length(tos_data);
    short_tos_count = sum(tos_data < 1);
    short_tos_ratio_rural(i) = (short_tos_count / total_tos_count) * 100;
end

% 🎨 Set별 색상 정의
bar_colors = [
    repmat([0, 0, 0.5], 4, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 3, 1);    % Set 5~7: 진한 갈색
    [0.6, 0, 0]                      % Set 8: 진한 붉은색
];

% 📊 막대 그래프
b = bar(short_tos_ratio_rural, 'FaceColor', 'flat');
b.CData = bar_colors;

% 🧭 축 설정
ylabel('Short ToS ratio (%)', 'FontSize', 17.5);
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
ylim([0, max(short_tos_ratio_rural) + 5]);
grid on; grid minor;

% ✅ 수치 표기
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = short_tos_ratio_rural(i);
    x = xt(i);
    y = value + 0.5;
    text(x, y, sprintf('%d', round(value)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_shortToS_ratio_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_shortToS_ratio_rural_only_coloredBySet.png'));

