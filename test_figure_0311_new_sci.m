clear all;

cases = 'case 1';
% case_path = 'fin_new_fin_2000';
case_path = 'MasterResults';
UE_num = 100;

% 결과 저장 폴더 설정
output_folder = '_MASTER_RESULTS_FIGURE_';

% 폴더가 없으면 생성
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

strategies_all = {'Strategy A', 'Strategy B', 'Strategy C', 'Strategy D', 'Strategy E', 'Strategy F', 'Strategy G', 'Strategy H'};
subset_indices = [1, 4, 7, 8, 9];  % A, D, G, J, K
scenarios = {'DenseUrban'};

display_names = {'Set 1', 'Set 2', 'Set 3', 'Set 4', 'Set 5', 'Set 6', 'Set 7', 'Set 8'}; 
% display_names = {'CHO (0 dB, 0 ms)', 'CHO (1 dB, 100 ms)', 'Set 3', 'Set 4', 'Set 5', 'Set 6', 'Set 7'}; 
% colors_all = { ...
%     [0, 0.447, 0.741], [0, 0.447, 0.741], [0, 0.447, 0.741], ...
%     [0.85, 0.325, 0.098], [0.635, 0.078, 0.184], [0.635 0.078 0.184], [0.494, 0.184, 0.556]}; % Strategy H와 I 제거된 색상
% lineStyles_all = { ...
%     ':', '--', '-.', ':', '--', '-.', '-', ':', '-.', '-'}; % Strategy H와 I에 대한 스타일 제거
colors_all = { ...
    [0, 0.447, 0.741], [0, 0.447, 0.741], ...
    [0, 0.447, 0.741], [0, 0.447, 0.741], ...
    [0.85, 0.325, 0.098], [0.635, 0.078, 0.184], [0.635 0.078 0.184], [0.494, 0.184, 0.556]}; % Strategy H와 I 제거된 색상
lineStyles_all = { ...
    ':', '--', '--', '--', '-.', '-.', '-.', '-'}; % Strategy H와 I에 대한 스타일 제거

% 부드러운 색상 설정
bar1_colors = [0, 0.447, 0.7410];  % 파란색
bar2_colors = [0.635, 0.078, 0.184];  % 빨간색
bar3_colors = [0.4940 0.1840 0.5560];  % 보라색

% Initialize data containers
raw_sinr_data_all = cell(length(scenarios), length(strategies_all));
sinr_data_all = cell(length(scenarios), length(strategies_all));
rlf_data_all = cell(length(scenarios), length(strategies_all));
uho_data_all = cell(length(scenarios), length(strategies_all));
ho_data_all = cell(length(scenarios), length(strategies_all));
uho_ho_ratio_all = cell(length(scenarios), length(strategies_all));
sub_tos_data_all = cell(length(scenarios), length(subset_indices));
tos_data_all = cell(length(scenarios), length(strategies_all));
hopp_data_all = cell(length(scenarios), length(strategies_all));
rbs_data_all = cell(length(scenarios), length(strategies_all));

%% Load data for each strategy and scenario
for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        % Corrected path using filesep
        data_path = fullfile(case_path, [cases, '_MASTER_RESULTS_', strategies_all{i}, '_', scenarios{s}, '.mat']);
        
        % Check if the file exists before attempting to load
        if exist(data_path, 'file') == 2
            loaded_data = load(data_path, 'MASTER_RAW_SINR', 'MASTER_UHO', 'MASTER_HO', 'MASTER_RLF', 'MASTER_SINR', 'MASTER_ToS', 'MASTER_HOPP', 'MASTER_RBs');
            
            raw_sinr_data_all{s, i} = loaded_data.MASTER_RAW_SINR(:);
            sinr_data_all{s, i} = loaded_data.MASTER_SINR(:);
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
total_sim_time = 173.21 / 7.56;

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
            % uho_per_ho_all(i, s) = round((total_uho / total_sim_time) / UE_num, 2);  % UHO per HO as a percentage
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

%% 반올림
raw_sinr_data_all = cellfun(@(x) round(x, 3), raw_sinr_data_all, 'UniformOutput', false);
sinr_data_all = cellfun(@(x) round(x, 3), sinr_data_all, 'UniformOutput', false);
uho_data_all = cellfun(@(x) round(x, 3), uho_data_all, 'UniformOutput', false);
ho_data_all = cellfun(@(x) round(x, 3), ho_data_all, 'UniformOutput', false);
rlf_data_all = cellfun(@(x) round(x, 3), rlf_data_all, 'UniformOutput', false);
hopp_data_all = cellfun(@(x) round(x, 3), hopp_data_all, 'UniformOutput', false);
uho_ho_ratio_all = cellfun(@(x) round(x, 3), uho_ho_ratio_all, 'UniformOutput', false);
sub_tos_data_all = cellfun(@(x) round(x, 3), sub_tos_data_all, 'UniformOutput', false);
tos_data_all = cellfun(@(x) round(x, 3), tos_data_all, 'UniformOutput', false);
hopp_per_ho_all = round(hopp_per_ho_all, 3);
uho_per_ho_all = round(uho_per_ho_all, 3);


%% Test Figure
figure('Position', [100, 100, 1000, 850]);
sinr_data_per_strategy_urban = [];
group_urban = [];

for i = 1:length(display_names)
    current_data = round(sinr_data_all{1, i}, 3);  % 소수점 3자리 반올림
    sinr_data_per_strategy_urban = [sinr_data_per_strategy_urban; current_data];  
    group_urban = [group_urban; i * ones(length(current_data), 1)]; 
end

boxplot(sinr_data_per_strategy_urban, group_urban, 'Labels', display_names);
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
set(gca, 'XTickLabel', display_names, 'FontSize', 17.5);  
grid on;
grid minor;

figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    sinr_data = raw_sinr_data_all{1, i};
    if ~isempty(sinr_data) && isvector(sinr_data)
        sinr_data_rounded = round(sinr_data, 3);
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
set(legend_handle, 'FontSize', 17.5);
xlim([-8 6]);
ylim([0 1]);
yticks(0:0.1:1);
grid on;
grid minor;

figure('Position', [100, 100, 1000, 850]);
hold on;
for i = 1:length(strategies_all)
    sinr_data = raw_sinr_data_all{1, i};
    if ~isempty(sinr_data)
        histogram(sinr_data, 'Normalization', 'probability', 'DisplayName', display_names{i}, ...
            'EdgeColor', colors_all{i}, 'FaceAlpha', 0.5);
    end
end
hold off;
xlabel('DL SINR [dB]', 'FontSize', 17.5);
ylabel('Probability', 'FontSize', 17.5);
legend('Location', 'northeast');
grid on;
grid minor;

figure('Position', [100, 100, 1000, 800]);
hold on;
for i = 1:length(strategies_all)
    sinr_data = sinr_data_all{1, i};
    if ~isempty(sinr_data)
        plot(1:length(sinr_data), sinr_data, 'LineWidth', 1.5, 'DisplayName', display_names{i});
    end
end
hold off;
xlabel('Time Step', 'FontSize', 17.5);
ylabel('SINR [dB]', 'FontSize', 17.5);
legend('Location', 'northeast');
grid on;
grid minor;

figure('Position', [100, 100, 1000, 800]);
hold on;
for i = 1:length(strategies_all)
    sinr_data = mean(sinr_data_all{1, i});
    ho_rate = mean(ho_data_all{1, i});
    scatter(sinr_data, ho_rate, 100, 'filled', 'DisplayName', display_names{i});
end
hold off;
xlabel('Mean SINR [dB]', 'FontSize', 17.5);
ylabel('Mean HO Rate', 'FontSize', 17.5);
legend('Location', 'northeast');
grid on;
grid minor;


% 시간 벡터 설정
START_TIME = 0;                 
SAT_SPEED = 7560;
TOTAL_TIME = 173.21 / 7.56;      % 전체 시뮬레이션 시간 (64.95, 86.6, 129.9, 173.2, 216.5)
SAMPLE_TIME = 0.2;              % 측정 주기 (10ms 단위)
STOP_TIME = TOTAL_TIME;         
TIMEVECTOR = START_TIME:SAMPLE_TIME:STOP_TIME;  % 시간 벡터 생성

% 전략 이름 리스트
strategies_all = {'Strategy A', 'Strategy B', 'Strategy C', 'Strategy D', 'Strategy E'};

% 그래프 생성
figure('Position', [100, 100, 1200, 600]);
hold on;

% 각 전략에 대해 SINR 데이터 플로팅
for i = 1:length(strategies_all)
    strategy_name = strategies_all{i};
    
    % raw_sinr_data_all에서 해당 전략의 데이터 가져오기
    if ~isempty(raw_sinr_data_all{1, i}) 
        sinr_data = raw_sinr_data_all{1, i};  % 해당 전략의 SINR 데이터
        
        % 시간 벡터와 SINR 데이터의 길이 조정
        min_length = min(length(TIMEVECTOR), length(sinr_data));
        plot(TIMEVECTOR(1:min_length), sinr_data(1:min_length), 'LineWidth', 1.5, 'DisplayName', strategy_name);
    else
        warning('SINR data for %s is empty or not valid.', strategy_name);
    end
end

hold off;
xlabel('Time (s)', 'FontSize', 14);
ylabel('SINR (dB)', 'FontSize', 14);
title('SINR Variation Over Time', 'FontSize', 16);
legend('Location', 'northeast');
grid on;
set(gca, 'FontSize', 12);

