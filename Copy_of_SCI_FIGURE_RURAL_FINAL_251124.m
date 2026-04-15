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
case_path = 'MasterResults2';

% 결과 저장 폴더 설정
output_folder = '_TVT_REV1_1127_RESULTS_FIGURE_2';
% 폴더가 없으면 생성
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

strategies_all = {'Strategy 1', 'Strategy 2', 'Strategy 3', 'Strategy 4', 'Strategy 5', 'Strategy 6', 'Strategy 7', 'Strategy 8'};
scenarios = {'Rural'};

% 색상 설정
display_names = {'Set 1', 'Set 2', 'Set 3', 'Set 4', 'Set 5', 'Set 6', 'Set 7', 'Set 8'}; 
comp_indices = 1:8; %(기존 인덱스 사용)
n_comp = length(comp_indices);

% =======================================
% Initialize data containers
raw_sinr_data_all = cell(length(scenarios), length(strategies_all));
raw_rsrp_data_all = cell(length(scenarios), length(strategies_all));
sinr_data_all = cell(length(scenarios), length(strategies_all));
rsrp_data_all = cell(length(scenarios), length(strategies_all));
rlf_data_all = cell(length(scenarios), length(strategies_all));
uho_data_all = cell(length(scenarios), length(strategies_all));
ho_data_all = cell(length(scenarios), length(strategies_all));
uho_ho_ratio_all = cell(length(scenarios), length(strategies_all));
% sub_tos_data_all = cell(length(scenarios), length(subset_indices));
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
            
            % % Load ToS data only for the subset strategies
            % if ismember(i, subset_indices) && isfield(loaded_data, 'MASTER_ToS')
            %     sub_tos_data_all{s, i == subset_indices} = loaded_data.MASTER_ToS(:);
            % end
            
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
        if total_ho > 0
             hopp_per_ho_all(i, s) = (total_hopp / total_ho) * 100;  % HO당 HOPP 비율 (%)로 계산
        else
             hopp_per_ho_all(i, s) = 0;
        end
    end
end

% Load HOPP Data for Each Strategy and Scenario (Re-loading logic kept as per original)
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
            % warning('File %s does not exist.', data_path); % Already warned above
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
        else
            uho_per_ho_all(i, s) = 0;  % HO가 없으면 0으로 설정
        end
        
        % HOPP per UHO 계산
        total_hopp = sum(hopp_data_all{s, i});  % Total HOPP count
        
        % UHO가 존재할 때만 HOPP per UHO 계산
        if total_uho > 0 && total_hopp > 0  % UHO와 HOPP가 모두 존재할 때만 계산
            hopp_per_ho_all(i, s) = (total_hopp / total_ho) * 100;  % HOPP per UHO as percentage
        else
            hopp_per_ho_all(i, s) = 0;  % UHO 또는 HOPP가 없으면 0으로 설정
        end
        
        % 디버그 정보 출력
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
% sub_tos_data_all = cellfun(@(x) round(x, 3), sub_tos_data_all, 'UniformOutput', false);
tos_data_all = cellfun(@(x) round(x, 3), tos_data_all, 'UniformOutput', false);
hopp_per_ho_all = round(hopp_per_ho_all, 3);
uho_per_ho_all = round(uho_per_ho_all, 3);

% 각 bar의 색상을 개별 설정 적용하기
% Plot: 초당 단말당 RLF, UHO/HO, HOPP/HO, UHO per HO & HOPP per UHO, SINR Box Plot, SINR CDF, RBs, ToS
% 각 figure의 subplot을 독립적으로 저장하도록 수정

% =========================================================================
% [UPDATED] Calculate Ratios & Comprehensive Logging
% =========================================================================
fprintf('\n================== SIMULATION KPI SUMMARY ==================\n');

% Initialize Arrays
uho_per_ho_all = zeros(length(strategies_all), length(scenarios));
hopp_per_ho_all = zeros(length(strategies_all), length(scenarios));

for s = 1:length(scenarios)
    for i = 1:length(strategies_all)
        % 1. 데이터 추출
        curr_ho_data = ho_data_all{s, i};
        curr_uho_data = uho_data_all{s, i};
        curr_hopp_data = hopp_data_all{s, i};
        curr_rlf_data = rlf_data_all{s, i};
        curr_rbs_data = rbs_data_all{s, i};
        curr_sinr_raw = raw_sinr_data_all{s, i};

        % 2. Total/Average 값 계산
        val_total_ho = sum(curr_ho_data);
        val_total_uho = sum(curr_uho_data);
        val_total_hopp = sum(curr_hopp_data);
        val_total_rlf = sum(curr_rlf_data);
        val_total_rb = sum(curr_rbs_data); % 전체 시뮬레이션 동안 소모된 총 RB (누적)
        val_avg_sinr = mean(curr_sinr_raw); % 전체 SINR 샘플의 평균

        % 3. 비율(Ratio) 계산 (기존 로직 유지)
        if val_total_ho > 0
            uho_per_ho_all(i, s) = (val_total_uho / val_total_ho) * 100;
        else
            uho_per_ho_all(i, s) = 0;
        end

        if val_total_uho > 0 && val_total_hopp > 0
            hopp_per_ho_all(i, s) = (val_total_hopp / val_total_ho) * 100;
        else
            hopp_per_ho_all(i, s) = 0;
        end
        
        % 4. [NEW] 통합 로그 출력 (정렬 적용)
        fprintf('Strategy: %-10s | Scen: %-8s | HO: %5d | UHO: %4d | HOPP: %4d | RLF: %4d | Tot RB: %8.1f | Avg SINR: %6.3f dB\n', ...
            strategies_all{i}, scenarios{s}, ...
            round(val_total_ho), round(val_total_uho), round(val_total_hopp), ...
            round(val_total_rlf), val_total_rb, val_avg_sinr);
    end
end
fprintf('============================================================\n\n');

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

% 🎨 Set별 색상 정의 (동적 크기 조정)
full_rural_colors = [
    repmat([0, 0, 0.5], 2, 1);       % Set 1~4: 진한 남색
    repmat([0.5, 0.25, 0], 4, 1);    % Set 5~7: 진한 갈색
    repmat([0.6, 0, 0], 4, 1);    % Set 8: 진한 붉은색
];
% 전략 수에 맞게 색상 자르기 (오류 방지)
rural_colors = full_rural_colors(1:length(strategies_all), :);

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
    text(xt(i), value + 0.013, sprintf('%.2f', value), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 12);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_rlf_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_rlf_rural_only_coloredBySet.png'));

% %% [SCI MAIN FIGURE] RLF (Left Bar) & HO Frequency (Right Bar) - Grouped Dual Axis
% figure('Position', [100, 100, 1100, 800]);
% 
% % 1. 데이터 준비
% % HO Rate (분당 단말당 핸드오버 횟수) 계산
% ho_rate_per_min = zeros(length(strategies_all), 1);
% % RLF 데이터는 이미 average_rlf_per_sec 변수에 있음
% 
% for i = 1:length(strategies_all)
%     ho_vec = ho_data_all{1, i}; 
%     ho_rate_per_min(i) = mean(ho_vec) / (TOTAL_TIME / 60);
% end
% 
% % 2. 막대 위치 설정 (겹침 방지)
% x_pos = 1:length(strategies_all);
% bar_width = 0.35; % 막대 너비
% offset = 0.2;     % 중심에서 떨어질 거리
% 
% % 3. 왼쪽 축: RLF (Bar Chart) - Set별 색상 적용
% yyaxis left
% % 왼쪽으로 이동 (x - offset)
% b_rlf = bar(x_pos - offset, average_rlf_per_sec, bar_width, 'FaceColor', 'flat');
% b_rlf.CData = rural_colors; % 기존 Set별 색상 유지
% 
% ylabel('Average RLF [Count/UE]', 'FontSize', 16, 'FontWeight', 'bold');
% set(gca, 'YColor', 'k'); % 축 색상 검정
% ylim([0, max(average_rlf_per_sec) * 1.35]); % 텍스트 공간 확보
% 
% % 4. 오른쪽 축: HO Frequency (Bar Chart) - 주황색 단색
% yyaxis right
% % 오른쪽으로 이동 (x + offset)
% b_ho = bar(x_pos + offset, ho_rate_per_min, bar_width, 'FaceColor', [0.85, 0.33, 0.1]);
% 
% ylabel('HO Frequency [HOs/UE/min]', 'FontSize', 16, 'FontWeight', 'bold');
% set(gca, 'YColor', [0.85, 0.33, 0.1]); % 축 색상 주황색
% ylim([0, max(ho_rate_per_min) * 1.25]); 
% 
% % 5. 공통 축 설정
% set(gca, 'XTick', x_pos, ...
%          'XTickLabel', display_names, ...
%          'FontSize', 14, 'FontWeight', 'bold');
% xlim([0.5, length(strategies_all) + 0.5]); % X축 범위
% grid on;
% ax = gca;
% ax.GridAlpha = 0.3;
% 
% % 6. 텍스트 라벨 추가
% for i = 1:length(strategies_all)
%     % (1) RLF 값 (왼쪽 막대 위)
%     yyaxis left
%     val_rlf = average_rlf_per_sec(i);
%     % 값이 0이거나 너무 작으면 표시 위치 조정 가능
%     text(i - offset, val_rlf, sprintf('%.2f', val_rlf), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 11, 'Color', 'k', 'FontWeight', 'bold');
% 
%     % (2) HO 값 (오른쪽 막대 위)
%     yyaxis right
%     val_ho = ho_rate_per_min(i);
%     text(i + offset, val_ho + (max(ho_rate_per_min)*0.02), sprintf('%.1f', val_ho), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 11, 'Color', [0.85, 0.33, 0.1], 'FontWeight', 'bold');
% end
% 
% % 7. 범례 추가
% legend([b_rlf, b_ho], {'RLF Count (Left)', 'HO Frequency (Right)'}, ...
%     'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 13);
% 
% % 8. 저장
% savefig(fullfile(output_folder, 'compare_RLF_and_HO_DualBar.fig'));
% saveas(gcf, fullfile(output_folder, 'compare_RLF_and_HO_DualBar.png'));

%% [SCI MAIN FIGURE] RLF (Light) & HO Frequency (Dark) - Both Colored by Set
figure('Position', [100, 100, 1100, 800]);

% 1. 색상 정의 (사용자 지정 Set 매핑)
% Set 1, 2 (2개): 진한 남색
color_group1 = [0, 0, 0.5];
% Set 3, 4, 5 (3개): 진한 갈색
color_group2 = [0.5, 0.25, 0];
% Set 6, 7, 8 (3개): 진한 붉은색
color_group3 = [0.6, 0, 0];

% (1) 진한 색상 (오른쪽 HO Frequency용)
colors_strong = [
    repmat(color_group1, 2, 1);
    repmat(color_group2, 3, 1);
    repmat(color_group3, 3, 1)
];

% (2) 연한 색상 (왼쪽 RLF용) - 흰색을 60% 섞음
colors_light = colors_strong + (1 - colors_strong) * 0.6;

% 2. 데이터 준비
ho_rate_per_min = zeros(length(strategies_all), 1);
for i = 1:length(strategies_all)
    ho_vec = ho_data_all{1, i}; 
    ho_rate_per_min(i) = mean(ho_vec) / (TOTAL_TIME / 60);
end

% 3. 막대 위치 설정
x_pos = 1:length(strategies_all);
bar_width = 0.35; 
offset = 0.2;     

% 4. 왼쪽 축: RLF (Bar Chart) -> [연한 Set 색상]
yyaxis left
b_rlf = bar(x_pos - offset, average_rlf_per_sec, bar_width, 'FaceColor', 'flat');
b_rlf.CData = colors_light; % 연한 색상 적용

ylabel('Average RLF [#/UE/min.]', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'YColor', 'k'); % 왼쪽 축 검정색
ylim([0, max(average_rlf_per_sec) * 1.25]); 

% 5. 오른쪽 축: HO Frequency (Bar Chart) -> [진한 Set 색상]
yyaxis right
b_ho = bar(x_pos + offset, ho_rate_per_min, bar_width, 'FaceColor', 'flat');
b_ho.CData = colors_strong; % 진한 색상 적용

ylabel('HO Frequency [HOs/UE/min]', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'YColor', 'k'); % 오른쪽 축도 검정색 (바 색상이 다양하므로)
ylim([0, max(ho_rate_per_min) * 1.25]); 

% 6. 공통 축 설정
set(gca, 'XTick', x_pos, ...
         'XTickLabel', display_names, ...
         'FontSize', 16, 'FontWeight', 'bold');
xlim([0.5, length(strategies_all) + 0.5]); 
grid on;
ax = gca;
ax.GridAlpha = 0.3;

% 7. 텍스트 라벨 추가
for i = 1:length(strategies_all)
    % (1) RLF 값 (왼쪽 막대)
    yyaxis left
    val_rlf = average_rlf_per_sec(i);
    text(i - offset, val_rlf, sprintf('%.2f', val_rlf), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, 'Color', 'k', 'FontWeight', 'bold');
        
    % (2) HO 값 (오른쪽 막대)
    yyaxis right
    val_ho = ho_rate_per_min(i);
    % 텍스트 색상을 진한 색상과 맞춰주거나 검정으로 통일
    % 여기선 가독성을 위해 검정(k) 혹은 해당 Set의 진한 색상 사용 가능
    text(i + offset, val_ho + (max(ho_rate_per_min)*0.02), sprintf('%.1f', val_ho), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, 'Color', 'k', 'FontWeight', 'bold');
end

% 8. 범례 추가 (더미 플롯 이용)
% 막대 색상이 다양하므로, 범례에는 "연한색=RLF", "진한색=HO"라는 스타일만 보여줍니다.
hold on;
% 회색(연한 느낌) 박스
dummy_light = plot(nan, nan, 's', 'MarkerSize', 15, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'none');
% 검정(진한 느낌) 박스
dummy_strong = plot(nan, nan, 's', 'MarkerSize', 15, 'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerEdgeColor', 'none');
hold off;

legend([dummy_light, dummy_strong], {'RLF Count (Lighter Bars)', 'HO Frequency (Darker Bars)'}, ...
    'Location', 'northeast', 'Orientation', 'horizontal', 'FontSize', 17);

% 9. 저장
savefig(fullfile(output_folder, 'compare_RLF_and_HO_DualBar_SetColored.fig'));
saveas(gcf, fullfile(output_folder, 'compare_RLF_and_HO_DualBar_SetColored.png'));

%% --------------------------------------------------------------------------------------------------------------------
% %% [SCI MAIN FIGURE] Average SINR (Rural Only + Set별 색상 적용)
% figure('Position', [100, 100, 1000, 850]);
% 
% % 데이터 준비
% sinr_data_per_strategy_rural = [];
% group_rural = [];
% for i = 1:length(display_names)
%     current_data = round(sinr_data_all{1, i}, 3);  % 소수점 3자리 반올림
%     sinr_data_per_strategy_rural = [sinr_data_per_strategy_rural; current_data];  
%     group_rural = [group_rural; i * ones(length(current_data), 1)];
% end
% 
% % boxplot 그리기
% boxplot(sinr_data_per_strategy_rural, group_rural, 'Labels', display_names, 'Colors', 'k');
% 
% % Box 색상 덮어씌우기
% h = findobj(gca, 'Tag', 'Box');
% % h는 역순으로 반환될 수 있으므로 주의
% for j = 1:length(h)
%     % h의 인덱스와 strategies의 인덱스 매핑 (역순 처리)
%     idx = length(h) - j + 1;
%     if idx <= size(rural_colors, 1)
%         patch(get(h(j), 'XData'), get(h(j), 'YData'), rural_colors(idx,:), 'FaceAlpha', 0.3);
%     end
%     % 중앙값 선을 검정색으로 진하게 설정
%     h_median = findobj(gca, 'Tag', 'Median');
%     set(h_median, 'Color', 'k', 'LineWidth', 1.8);  % 중앙값 선 두껍게
% end
% 
% % 라벨 설정
% ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
% set(gca, 'XTickLabel', display_names, 'FontSize', 17.5);
% grid on;
% grid minor;
% 
% % 저장
% savefig(fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.fig'));
% saveas(gcf, fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.png'));

%% [SCI MAIN FIGURE] Average SINR (Rural Only + Set별 색상 적용) - [오류 수정됨]
figure('Position', [100, 100, 1000, 850]);

% 1. 데이터 준비
sinr_data_per_strategy_rural = [];
group_rural = [];

for i = 1:length(display_names)
    % 데이터가 존재하고 비어있지 않은 경우에만 추가
    if i <= size(sinr_data_all, 2) && ~isempty(sinr_data_all{1, i})
        current_data = round(sinr_data_all{1, i}, 3);  % 소수점 3자리 반올림
        sinr_data_per_strategy_rural = [sinr_data_per_strategy_rural; current_data];  
        group_rural = [group_rural; i * ones(length(current_data), 1)];
    end
end

% 2. [핵심 수정] 실제 데이터가 있는 그룹만 추출
if ~isempty(group_rural)
    present_indices = unique(group_rural); % 실제 데이터가 있는 인덱스 (예: 1, 2, 4...)
    valid_labels = display_names(present_indices); % 해당 인덱스의 라벨만 추출
    
    % 3. boxplot 그리기 (라벨 개수 일치시킴)
    boxplot(sinr_data_per_strategy_rural, group_rural, 'Labels', valid_labels, 'Colors', 'k');

    % 4. Box 색상 덮어씌우기 (인덱스 매핑 수정)
    h = findobj(gca, 'Tag', 'Box');
    num_boxes = length(h);
    
    % boxplot 객체(h)는 역순으로 저장됨 (오른쪽 -> 왼쪽)
    % present_indices는 오름차순 (왼쪽 -> 오른쪽)
    for j = 1:num_boxes
        % 1) 현재 처리 중인 상자가 present_indices에서 몇 번째인지 계산
        array_idx = num_boxes - j + 1; 
        
        % 2) 실제 전략 번호(Set 번호) 가져오기
        real_strategy_idx = present_indices(array_idx);
        
        % 3) 해당 전략 번호에 맞는 색상 적용
        if real_strategy_idx <= size(rural_colors, 1)
            patch(get(h(j), 'XData'), get(h(j), 'YData'), rural_colors(real_strategy_idx, :), 'FaceAlpha', 0.3);
        end
    end

    % 중앙값 선을 검정색으로 진하게 설정
    h_median = findobj(gca, 'Tag', 'Median');
    set(h_median, 'Color', 'k', 'LineWidth', 1.8);
    
    % 라벨 설정
    ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
    set(gca, 'FontSize', 15); % 축 폰트 일괄 설정
    grid on;
    grid minor;

    % 저장
    savefig(fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.fig'));
    saveas(gcf, fullfile(output_folder, 'results_DLSINR_box_rural_coloredBySet.png'));
else
    warning('No SINR data available to plot boxplot.');
    close(gcf);
end


% %% AVERAGE SINR - new 바이올린 플롯으로 유력한 MAIN
% figure('Position', [70, 70, 930, 730]);
% hold on;
% 
% % 색상 정의 (위에서 만든 box_colors 사용)
% % box_colors = box_colors(1:length(strategies_all), :);
% 
% % 평균/중앙값 마커 저장용
% mean_handles = gobjects(1,1);
% median_handles = gobjects(1,1);
% 
% for i = 1:length(display_names)
%     y_data = round(sinr_data_all{1, i}, 3);
% 
%     % 분포 곡선
%     [f, xi] = ksdensity(y_data);
%     f = f / max(f) * 0.3;  % 정규화 후 너비 조절
%     fill([i - f, fliplr(i + f)], [xi, fliplr(xi)], rural_colors(i, :), ...
%         'FaceAlpha', 0.35, 'EdgeColor', 'none');
% 
%     % 중앙값 (점선)
%     median_val = median(y_data);
%     median_handles = plot([i - 0.2, i + 0.2], [median_val, median_val], ...
%         'k:', 'LineWidth', 2.0);  % 점선으로 표기
% 
%     % 평균 (빈 원)
%     mean_val = mean(y_data);
%     mean_handles = plot(i, mean_val, 'ko', 'MarkerSize', 7, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');
% end
% 
% xlim([0.5, length(display_names) + 0.5]);
% ylim([-4.8, -0.7]);
% xticks(1:length(display_names));
% xticklabels(display_names);
% ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
% set(gca, 'FontSize', 15);
% grid on; grid minor;
% 
% % 범례 추가
% legend([median_handles, mean_handles], {'Median value', 'Mean value'}, ...
%     'Location', 'southwest', 'FontSize', 13);
% 
% % 저장
% savefig(fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.fig'));
% saveas(gcf, fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.png'));

%% AVERAGE SINR - Violin Plot (MAIN, colors_strong 적용)
figure('Position', [70, 70, 930, 730]);
hold on;

% 평균/중앙값 마커 저장용 변수 초기화
mean_handles   = gobjects(1,1);
median_handles = gobjects(1,1);
has_valid_plot = false; % 범례 생성을 위한 플래그

% ★ Set별 색상: display_names/strategies_all 개수만큼 사용
colors_violin = colors_strong(1:length(display_names), :);

for i = 1:length(display_names)
    % 1. 인덱스 범위 확인 (데이터보다 라벨이 많을 경우 방지)
    if i > size(sinr_data_all, 2)
        continue;
    end

    y_data = round(sinr_data_all{1, i}, 3);

    % 2. 데이터가 비어있거나 너무 적으면 ksdensity 실행 건너뛰기
    if isempty(y_data) || sum(~isnan(y_data)) < 2
        continue; 
    end

    % 3. 분포 곡선 (ksdensity)
    [f, xi] = ksdensity(y_data);
    f = f / max(f) * 0.3;  % 정규화 후 너비 조절
    
    % ★ i번째 Set는 colors_violin(i,:) 색 사용
    fill([i - f, fliplr(i + f)], [xi, fliplr(xi)], colors_violin(i, :), ...
        'FaceAlpha', 0.35, 'EdgeColor', 'none');

    % 4. 중앙값 (점선)
    median_val = median(y_data);
    median_handles = plot([i - 0.2, i + 0.2], [median_val, median_val], ...
        'k:', 'LineWidth', 2.0);  % 점선으로 표기

    % 5. 평균 (빈 원)
    mean_val = mean(y_data);
    mean_handles = plot(i, mean_val, 'ko', ...
        'MarkerSize', 7, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');
    
    has_valid_plot = true;
end

% 축 및 라벨 설정
xlim([0.5, length(display_names) + 0.5]);
xticks(1:length(display_names));
xticklabels(display_names);
ylabel('Average DL SINR [dB]', 'FontSize', 17.5);
set(gca, 'FontSize', 15);
grid on; grid minor;

% 필요하면 Y축 범위 고정 (이전 설정 유지하고 싶으면 주석 해제)
% ylim([-4.8, -0.7]); 

% 범례 추가 (플롯이 하나라도 그려졌을 때만)
if has_valid_plot
    legend([median_handles, mean_handles], {'Median value', 'Mean value'}, ...
        'Location', 'southwest', 'FontSize', 16);
end

% 저장
savefig(fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.fig'));
saveas(gcf, fullfile(output_folder, 'results_DLSINR_violin_median_mean_rural_legend.png'));

%% [SCI MAIN FIGURE] Average RBs (Rural Only + Set별 색상)
figure('Position', [100, 100, 1000, 800]);

% 📌 Rural만 평균 계산
mean_rbs_per_rural = zeros(length(strategies_all), 1);
for i = 1:length(strategies_all)
    avg_hos_times = mean(ho_data_all{1, i}) / TOTAL_TIME;  % 1: Rural
    avg_rbs_times =  mean(rbs_data_all{1, i})/TOTAL_TIME;
    avg_hos_times2 = mean(ho_data_all{1, i});  % 1: Rural
    avg_rbs_times2 =  mean(rbs_data_all{1, i});
    mean_rbs_per_rural(i) = round(avg_rbs_times, 2);  % 평균 RBs 사용량 (소수점 2자리)
end

% 🎨 Set별 색상 정의 (재사용)
% rural_colors 이미 사이즈 조정됨

% 📊 막대 그래프
b = bar(mean_rbs_per_rural, 'FaceColor', 'flat');
b.CData = colors_strong;

% 🧭 축 설정
ylabel('RBs usage [#/UE/s]', 'FontSize', 17.5);
set(gca, 'XTick', 1:length(strategies_all), ...
         'XTickLabel', display_names, ...
         'FontSize', 17.5);
ylim([0, max(mean_rbs_per_rural) + 0.5]);
grid on;
grid minor;

% ✅ 수치 표기
xt = get(gca, 'XTick');
for i = 1:length(strategies_all)
    value = mean_rbs_per_rural(i);
    x = xt(i);
    y = value + 0.1;
    text(x, y, sprintf('%.2f', value), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 13);
end

% 💾 저장
savefig(fullfile(output_folder, 'compare_avgRBs_rural_only_coloredBySet.fig'));
saveas(gcf, fullfile(output_folder, 'compare_avgRBs_rural_only_coloredBySet.png'));


% %% [SCI MAIN FIGURE] Short ToS (Rural Only + 색상 적용)
% figure('Position', [100, 100, 1000, 800]);
% 
% % 📌 Rural (s = 1)만 Short ToS 계산
% short_tos_ratio_rural = zeros(length(strategies_all), 1);
% for i = 1:length(strategies_all)
%     tos_data = tos_data_all{1, i};  % 1: Rural
%     if ~isempty(tos_data)
%         total_tos_count = length(tos_data);
%         short_tos_count = sum(tos_data < 1);
%         short_tos_ratio_rural(i) = (short_tos_count / total_tos_count) * 100;
%     end
% end
% 
% % 🎨 Set별 색상 정의 (재사용)
% % rural_colors 이미 사이즈 조정됨
% 
% % 📊 막대 그래프
% b = bar(short_tos_ratio_rural, 'FaceColor', 'flat');
% b.CData = rural_colors;
% 
% % 🧭 축 설정
% ylabel('Short ToS ratio (%)', 'FontSize', 17.5);
% set(gca, 'XTick', 1:length(strategies_all), ...
%          'XTickLabel', display_names, ...
%          'FontSize', 17.5);
% ylim([0, max(short_tos_ratio_rural) + 5]);
% grid on; grid minor;
% 
% % ✅ 수치 표기
% xt = get(gca, 'XTick');
% for i = 1:length(strategies_all)
%     value = short_tos_ratio_rural(i);
%     x = xt(i);
%     y = value + 0.5;
%     text(x, y, sprintf('%d', round(value)), ...
%         'HorizontalAlignment', 'center', ...
%         'FontSize', 13);
% end
% 
% % 💾 저장
% savefig(fullfile(output_folder, 'compare_shortToS_ratio_rural_only_coloredBySet.fig'));
% saveas(gcf, fullfile(output_folder, 'compare_shortToS_ratio_rural_only_coloredBySet.png'));
% 
% fprintf('All figures generated successfully.\n');

% %% [SCI MAIN FIGURE] Average ToS (Rural Only + 색상 적용)
% figure('Position', [100, 100, 1000, 800]);
% 
% % 📌 Rural (s = 1)만 Average ToS 계산
% mean_tos_rural = zeros(length(strategies_all), 1);
% for i = 1:length(strategies_all)
%     tos_data = tos_data_all{1, i};  % 1: Rural
%     if ~isempty(tos_data)
%         mean_tos_rural(i) = mean(tos_data); % 평균값 계산
%     end
% end
% 
% % 🎨 Set별 색상 정의 (Short ToS와 동일한 로직)
% % (만약 위에서 rural_colors가 이미 정의되어 있다면 이 부분은 주석 처리해도 됨)
% % 📊 막대 그래프
% b = bar(mean_tos_rural, 'FaceColor', 'flat');
% b.CData = rural_colors;
% 
% % 🧭 축 설정
% ylabel('Average Time-of-Stay [s]', 'FontSize', 17.5);
% set(gca, 'XTick', 1:length(strategies_all), ...
%          'XTickLabel', display_names, ...
%          'FontSize', 17.5);
% ylim([0, max(mean_tos_rural) * 1.15]); % 여유 공간 확보
% grid on; grid minor;
% 
% % ✅ 수치 표기
% xt = get(gca, 'XTick');
% for i = 1:length(strategies_all)
%     value = mean_tos_rural(i);
%     x = xt(i);
%     y = value + 0.1; % ToS 값에 맞춰 위치 조정 (초 단위이므로 작게)
%     text(x, y, sprintf('%.2f', value), ...
%         'HorizontalAlignment', 'center', ...
%         'FontSize', 13);
% end
% 
% % 💾 저장
% savefig(fullfile(output_folder, 'compare_avg_ToS_rural_only_coloredBySet.fig'));
% saveas(gcf, fullfile(output_folder, 'compare_avg_ToS_rural_only_coloredBySet.png'));

%% [FINAL FIGURE] Overlay Style (Bar + Floating Marker)
figure('Position', [100, 100, 1000, 750]);

% 📌 Rural (s = 1)만 Average ToS 계산
mean_tos_rural = zeros(length(strategies_all), 1);
for i = 1:length(strategies_all)
    tos_data = tos_data_all{1, i};  % 1: Rural
    if ~isempty(tos_data)
        mean_tos_rural(i) = mean(tos_data); % 평균값 계산
    end
end

% 📌 Rural (s = 1)만 Short ToS 계산
short_tos_ratio_rural = zeros(length(strategies_all), 1);
for i = 1:length(strategies_all)
    tos_data = tos_data_all{1, i};  % 1: Rural
    if ~isempty(tos_data)
        total_tos_count = length(tos_data);
        short_tos_count = sum(tos_data < 1);
        short_tos_ratio_rural(i) = (short_tos_count / total_tos_count) * 100;
    end
end

% 1. 왼쪽 축: Bar Chart (넓게)
yyaxis left
b_ov = bar(mean_tos_rural, 0.6, 'FaceColor', 'flat'); % 너비 0.6
b_ov.CData = colors_strong; 
b_ov.FaceAlpha = 0.6; % 투명도를 주어 뒤에 격자가 보이게 하고 마커 강조

ylabel('Average Time-of-Stay [s]', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'YColor', 'k'); 
ylim([0, max(mean_tos_rural) * 1.3]); 

% 2. 오른쪽 축: Marker Only (선 없음, 중앙 정렬)
yyaxis right
p_ov = plot(short_tos_ratio_rural, 'p', ... % 'p'는 오각형(Pentagram) 별
    'LineStyle', 'none', ...
    'MarkerSize', 15, ...          % 마커를 매우 크게
    'MarkerFaceColor', [0.85, 0.33, 0.1], ... % 진한 주황 채우기
    'MarkerEdgeColor', 'k', ...    % 테두리 검정
    'LineWidth', 1.5);

ylabel('Short ToS Ratio (%)', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'YColor', [0.85, 0.33, 0.1]);
ylim([0, max(short_tos_ratio_rural) * 3.5]); % 마커 공간 확보

% 3. 공통 설정
set(gca, 'XTick', 1:length(strategies_all), 'XTickLabel', display_names, ...
    'FontSize', 14, 'FontWeight', 'bold');
grid on;
ax = gca; ax.GridAlpha = 0.4; ax.LineWidth = 1.2;

% 4. 범례
legend([b_ov, p_ov], {'Avg ToS (Bar)', 'Short ToS % (Star Marker)'}, ...
    'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 13);

% 5. 텍스트 라벨 (위치 겹침 방지)
for i = 1:length(strategies_all)
    % Bar 값 (막대 내부 상단)
    yyaxis left
    text(i, mean_tos_rural(i), sprintf('%.2fs', mean_tos_rural(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 11, 'Color', 'k', 'FontWeight', 'bold', 'Interpreter', 'none');
    
    % Marker 값 (마커 바로 위)
    yyaxis right
    val = short_tos_ratio_rural(i);
    if val > 0
        text(i, val + 1, sprintf('%.1f%%', val), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 12, 'Color', [0.85, 0.33, 0.1], 'FontWeight', 'bold');
    end
end

% 저장
savefig(fullfile(output_folder, 'FINAL_Fig_Overlay.fig'));
saveas(gcf, fullfile(output_folder, 'FINAL_Fig_Overlay.png'));


%% [FINAL FIGURE] Average ToS with Short ToS Ratio Text
figure('Position', [100, 100, 1100, 800]);

% 1. 데이터 준비
mean_tos_rural = zeros(length(strategies_all), 1);
short_tos_ratio_rural = zeros(length(strategies_all), 1);

for i = 1:length(strategies_all)
    tos_data = tos_data_all{1, i}; % Rural
    if ~isempty(tos_data)
        mean_tos_rural(i) = mean(tos_data);
        
        total_len = length(tos_data);
        short_len = sum(tos_data < 1);
        if total_len > 0
            short_tos_ratio_rural(i) = (short_len / total_len) * 100;
        end
    end
end

% 2. 막대 그래프 그리기 (Average ToS 기준)
b = bar(mean_tos_rural, 'FaceColor', 'flat');

% ★ Set별 색상: colors_strong 사용 (행 수가 전략 개수 이상이라고 가정)
colors_bar = colors_strong(1:length(strategies_all), :);
b.CData = colors_bar;

% 3. 축 설정
ylabel('Average Time-of-Stay [s]', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'XTick', 1:length(strategies_all), 'XTickLabel', display_names, ...
    'FontSize', 14, 'FontWeight', 'bold');
grid on;
ylim([0, max(mean_tos_rural) * 1.25]); % 텍스트 들어갈 공간 확보

% 4. 텍스트 라벨 추가 (핵심)
% 막대 위: 검은색은 "시간", 주황색/회색은 "비율(Short ToS)"
for i = 1:length(strategies_all)
    h_val = mean_tos_rural(i);        % Avg ToS [s]
    r_val = short_tos_ratio_rural(i); % Short ToS ratio [%]
    
    % (1) 시간 표시 (검정색)
    text(i, h_val + (max(mean_tos_rural)*0.08), sprintf('%.2fs', h_val), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 12, 'Color', 'k', 'FontWeight', 'bold');
    
    % (2) 비율 표시 (주황/회색)
    if r_val > 0
        ratio_str = sprintf('(%.1f%%)', r_val);
        text_color = [1, 0.1, 0.1];  % 진한 주황/빨강
    else
        ratio_str = '(0.0%)';
        text_color = [1, 0.1, 0.1];    % 회색 (0%는 덜 강조)
    end
    
    text(i, h_val + (max(mean_tos_rural)*0.02), ratio_str, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11, 'Color', text_color, 'FontWeight', 'bold');
end

% 5. 범례 (dummy plot 이용)
hold on;
h_dummy1 = plot(nan, nan, 's', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none'); 
h_dummy2 = plot(nan, nan, 's', 'MarkerFaceColor', [0.85, 0.33, 0.1], 'MarkerEdgeColor', 'none'); 
legend([h_dummy1, h_dummy2], {'Value: Avg ToS [s]', 'Value: Short ToS Ratio [%]'}, ...
    'Location', 'northwest', 'FontSize', 15);
hold off;

% 6. 저장
savefig(fullfile(output_folder, 'FINAL_Fig_ToS_Annotated.fig'));
saveas(gcf, fullfile(output_folder, 'FINAL_Fig_ToS_Annotated.png'));




% %% [FINAL FIGURE] Subplots (Vertical Separation)
% figure('Position', [100, 100, 1000, 900]);
% 
% % --- 상단 그래프: Average ToS ---
% subplot(2, 1, 1); 
% b1 = bar(mean_tos_rural, 'FaceColor', 'flat');
% b1.CData = rural_colors; % 기존 Set별 색상 유지
% 
% ylabel('Average ToS [s]', 'FontSize', 15, 'FontWeight', 'bold');
% title('Comparison of Time-of-Stay & Short ToS Ratio', 'FontSize', 16);
% set(gca, 'XTickLabel', []); % 상단 그래프 X축 라벨 생략 (깔끔하게)
% set(gca, 'XTick', 1:length(strategies_all));
% grid on; grid minor;
% ylim([0, max(mean_tos_rural)*1.2]); 
% 
% % 값 표시 (Top)
% for i = 1:length(strategies_all)
%     text(i, mean_tos_rural(i), sprintf('%.2fs', mean_tos_rural(i)), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%         'FontSize', 11, 'FontWeight', 'bold');
% end
% 
% % --- 하단 그래프: Short ToS Ratio ---
% subplot(2, 1, 2);
% % 막대 대신 줄기(Stem) 차트나 굵은 막대 사용. 여기선 명확한 대비를 위해 단색 막대 추천
% b2 = bar(short_tos_ratio_rural, 'FaceColor', [0.85, 0.33, 0.1]); 
% 
% ylabel('Short ToS Ratio (%)', 'FontSize', 15, 'FontWeight', 'bold');
% set(gca, 'XTick', 1:length(strategies_all), 'XTickLabel', display_names, ...
%     'FontSize', 13, 'FontWeight', 'bold');
% grid on; grid minor;
% ylim([0, max(short_tos_ratio_rural) + 10]);
% 
% % 값 표시 (Bottom)
% for i = 1:length(strategies_all)
%     val = short_tos_ratio_rural(i);
%     text(i, val, sprintf('%.1f%%', val), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%         'FontSize', 11, 'Color', [0.85, 0.33, 0.1], 'FontWeight', 'bold');
% end
% 
% % 그래프 간격 조정
% pos1 = get(subplot(2,1,1), 'Position');
% pos2 = get(subplot(2,1,2), 'Position');
% % 아래 그래프를 위로 살짝 올림
% set(subplot(2,1,2), 'Position', [pos2(1), pos2(2)+0.03, pos2(3), pos2(4)]);
% 
% % 저장
% savefig(fullfile(output_folder, 'FINAL_Fig_Subplots.fig'));
% saveas(gcf, fullfile(output_folder, 'FINAL_Fig_Subplots.png'));

% %% [FINAL FIGURE] Combined Average ToS & Short ToS Ratio (Dual Y-Axis)
% figure('Position', [100, 100, 1000, 800]);
% 
% % 1. 데이터 계산 (Rural Only)
% mean_tos_rural = zeros(length(strategies_all), 1);
% short_tos_ratio_rural = zeros(length(strategies_all), 1);
% 
% for i = 1:length(strategies_all)
%     tos_data = tos_data_all{1, i};  % 1: Rural
%     if ~isempty(tos_data)
%         % Metric 1: Average ToS
%         mean_tos_rural(i) = mean(tos_data);
% 
%         % Metric 2: Short ToS Ratio
%         total_tos_count = length(tos_data);
%         short_tos_count = sum(tos_data < 1);
%         if total_tos_count > 0
%             short_tos_ratio_rural(i) = (short_tos_count / total_tos_count) * 100;
%         else
%             short_tos_ratio_rural(i) = 0;
%         end
%     end
% end
% 
% % 2. 왼쪽 축: Average ToS (Bar Chart)
% yyaxis left
% b_comb = bar(mean_tos_rural, 'FaceColor', 'flat');
% b_comb.CData = rural_colors; % 기존 Set별 색상 적용
% 
% % 왼쪽 축 설정
% ylabel('Average Time-of-Stay [s]', 'FontSize', 17.5, 'FontWeight', 'bold');
% set(gca, 'YColor', 'k'); % 왼쪽 축 색상을 검정으로 (다색 막대이므로)
% ylim([0, max(mean_tos_rural) * 1.25]); % 텍스트 공간 확보
% 
% % 3. 오른쪽 축: Short ToS Ratio (Line Plot)
% yyaxis right
% % 선 그래프 스타일: 진한 붉은색 실선 + 마커
% p_comb = plot(short_tos_ratio_rural, '-o', ...
%     'LineWidth', 2.5, ...
%     'MarkerSize', 8, ...
%     'MarkerFaceColor', 'w', ...
%     'Color', [0.85, 0.33, 0.1]); 
% 
% % 오른쪽 축 설정
% ylabel('Short ToS Ratio (%)', 'FontSize', 17.5, 'FontWeight', 'bold');
% set(gca, 'YColor', [0.85, 0.33, 0.1]); % 오른쪽 축 색상을 선 색상과 일치
% ylim([0, max(short_tos_ratio_rural) + 10]); % 여유 공간
% 
% % 4. 공통 축 설정
% set(gca, 'XTick', 1:length(strategies_all), ...
%          'XTickLabel', display_names, ...
%          'FontSize', 15, 'FontWeight', 'bold');
% grid on; 
% ax = gca;
% ax.GridAlpha = 0.3; % 그리드 투명도 조절
% 
% % 5. 수치 텍스트 추가 (막대와 선 모두)
% xt = 1:length(strategies_all);
% 
% for i = 1:length(strategies_all)
%     % (1) Average ToS 값 표시 (왼쪽 축 기준, 막대 위)
%     % yyaxis left가 활성화된 상태에서 text를 찍거나, 좌표를 잘 계산해야 함.
%     % 가장 안전한 방법은 text 객체를 생성할 때 정규화된 단위를 쓰거나,
%     % 단순히 값을 표기하되 위치를 데이터 좌표계에 맞추는 것입니다.
% 
%     % 왼쪽 축 데이터 좌표계 사용을 위해 잠시 활성화
%     yyaxis left
%     val_bar = mean_tos_rural(i);
%     text(xt(i), val_bar + (max(mean_tos_rural)*0.02), sprintf('%.2fs', val_bar), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 12, 'Color', 'k', 'FontWeight', 'bold');
% 
%     % (2) Short ToS 값 표시 (오른쪽 축 기준, 마커 위)
%     yyaxis right
%     val_line = short_tos_ratio_rural(i);
%     text(xt(i), val_line + 2, sprintf('%.1f%%', val_line), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 12, 'Color', [0.85, 0.33, 0.1], 'FontWeight', 'bold');
% end
% 
% % 6. 범례 추가
% legend([b_comb, p_comb], {'Avg ToS (Left)', 'Short ToS % (Right)'}, ...
%     'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 13);
% 
% % 7. 저장
% savefig(fullfile(output_folder, 'FINAL_Fig_Combined_ToS_and_ShortToS.fig'));
% saveas(gcf, fullfile(output_folder, 'FINAL_Fig_Combined_ToS_and_ShortToS.png'));

% %% [FINAL FIGURE] Combined Average ToS & Short ToS (Dual-Axis Grouped Bars)
% figure('Position', [100, 100, 1200, 800]); % 가로를 조금 더 넓게 설정
% 
% % 1. 데이터 준비
% mean_tos_rural = zeros(length(strategies_all), 1);
% short_tos_ratio_rural = zeros(length(strategies_all), 1);
% 
% for i = 1:length(strategies_all)
%     tos_data = tos_data_all{1, i}; 
%     if ~isempty(tos_data)
%         mean_tos_rural(i) = mean(tos_data);
%         total_tos_count = length(tos_data);
%         short_tos_count = sum(tos_data < 1);
%         if total_tos_count > 0
%             short_tos_ratio_rural(i) = (short_tos_count / total_tos_count) * 100;
%         else
%             short_tos_ratio_rural(i) = 0;
%         end
%     end
% end
% 
% % 2. 막대 위치 설정 (겹치지 않게 오프셋 적용)
% x_pos = 1:length(strategies_all);
% bar_width = 0.35;             % 막대 너비
% offset = 0.2;                 % 중심에서 떨어질 거리 (너비의 절반 정도)
% 
% % 3. 왼쪽 축 그리기 (Average ToS) - 파란색 계열
% yyaxis left
% % X축 위치를 왼쪽으로(x_pos - offset) 이동
% b1 = bar(x_pos - offset, mean_tos_rural, bar_width, 'FaceColor', [0, 0.447, 0.741]); 
% ylabel('Average Time-of-Stay [s]', 'FontSize', 16, 'FontWeight', 'bold');
% set(gca, 'YColor', [0, 0.447, 0.741]); % 축 색상 일치
% ylim([0, max(mean_tos_rural) * 1.25]); % 여유 공간
% 
% % 4. 오른쪽 축 그리기 (Short ToS %) - 붉은색 계열
% yyaxis right
% % X축 위치를 오른쪽으로(x_pos + offset) 이동
% b2 = bar(x_pos + offset, short_tos_ratio_rural, bar_width, 'FaceColor', [0.85, 0.325, 0.098]);
% ylabel('Short ToS Ratio (%)', 'FontSize', 16, 'FontWeight', 'bold');
% set(gca, 'YColor', [0.85, 0.325, 0.098]); % 축 색상 일치
% ylim([0, max(short_tos_ratio_rural) + 10]); % 여유 공간
% 
% % 5. 공통 축 설정
% set(gca, 'XTick', x_pos, ...
%          'XTickLabel', display_names, ...
%          'FontSize', 14, 'FontWeight', 'bold');
% xlim([0.5, length(strategies_all) + 0.5]); % X축 범위 고정
% grid on;
% ax = gca;
% ax.GridAlpha = 0.3;
% 
% % 6. 범례 추가
% legend([b1, b2], {'Avg ToS (Left Axis)', 'Short ToS % (Right Axis)'}, ...
%        'Location', 'north', 'Orientation', 'horizontal', 'FontSize', 13);
% 
% % 7. 수치 텍스트 추가 (위치 계산 중요)
% for i = 1:length(strategies_all)
%     % (1) 왼쪽 막대 텍스트 (파란색)
%     yyaxis left
%     val1 = mean_tos_rural(i);
%     % x위치: i - offset
%     text(i - offset, val1 + (max(mean_tos_rural)*0.02), sprintf('%.2fs', val1), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 10, 'Color', [0, 0.447, 0.741], 'FontWeight', 'bold');
% 
%     % (2) 오른쪽 막대 텍스트 (붉은색)
%     yyaxis right
%     val2 = short_tos_ratio_rural(i);
%     % x위치: i + offset
%     % 0%인 경우 겹치지 않게 약간 위로 띄움
%     txt_height = val2 + 1; 
%     text(i + offset, txt_height, sprintf('%.1f%%', val2), ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'bottom', ...
%         'FontSize', 10, 'Color', [0.85, 0.325, 0.098], 'FontWeight', 'bold');
% end
% 
% % 8. 저장
% savefig(fullfile(output_folder, 'FINAL_Fig_Combined_DualBar.fig'));
% saveas(gcf, fullfile(output_folder, 'FINAL_Fig_Combined_DualBar.png'));

%% DO NOT REMOVE
% [핵심] 정규화 계수 (분당 단말당 횟수로 변환)
norm_factor = (1 / (UE_num * TOTAL_TIME)) * 60;

% 데이터 담을 배열 초기화
val_essential_norm = zeros(1, n_comp);
val_wasted_norm = zeros(1, n_comp);
val_total_norm = zeros(1, n_comp);

for k = 1:n_comp
    idx = comp_indices(k);

    % 데이터 추출 (Rural: s=1)
    curr_ho_count = sum(ho_data_all{1, idx});
    curr_uho_count = sum(uho_data_all{1, idx});

    % [수정] RB 곱하기(x10) 제거 -> 순수 횟수에 정규화 적용
    % Essential: 유효한 핸드오버 (전체 - UHO)
    val_essential_norm(k) = (curr_ho_count - curr_uho_count) * norm_factor;

    % Wasted: 불필요한 핸드오버 (UHO)
    val_wasted_norm(k) = curr_uho_count * norm_factor;

    % Total
    val_total_norm(k) = val_essential_norm(k) + val_wasted_norm(k);
end

%% ========================================================================
% [Final Figure C] Efficiency Analysis (Breakdown: Essential, UHO, HOPP)
% 수정 사항:
% 1. Wasted Cost 분해: UHO(Red)와 HOPP(Purple)로 나누어 적층 (Stack)
% 2. 데이터 무결성: HOPP는 UHO의 부분집합이므로, 'Pure UHO = Total UHO - HOPP'로 계산
% 3. 시각화: HOPP가 있는 경우(Set 1) 가장 위에 보라색으로 표시하여 눈에 띄게 함
% ========================================================================

figure('Position', [200, 200, 900, 700]);

% 정규화 계수 (분당 단말당 횟수)
norm_factor = (1 / (UE_num * TOTAL_TIME)) * 60;

% 데이터 담을 배열 초기화
val_essential_norm = zeros(1, n_comp);
val_uho_pure_norm = zeros(1, n_comp); % HOPP를 제외한 순수 UHO
val_hopp_norm = zeros(1, n_comp);     % HOPP (Ping-Pong)
val_total_norm = zeros(1, n_comp);
val_wasted_total_norm = zeros(1, n_comp); % 텍스트 표기용 (UHO + HOPP)

for k = 1:n_comp
    idx = comp_indices(k);
    
    % 데이터 추출 (Rural: s=1)
    curr_ho_count = sum(ho_data_all{1, idx});
    curr_uho_count = sum(uho_data_all{1, idx});
    curr_hopp_count = sum(hopp_data_all{1, idx}); % HOPP 데이터 추가
    
    % [데이터 분해]
    % 1. Essential (필수): 전체 HO - UHO (UHO 안에 HOPP가 포함되어 있으므로 전체 UHO를 뺌)
    val_essential_norm(k) = (curr_ho_count - curr_uho_count) * norm_factor;
    
    % 2. HOPP (핑퐁): 가장 악성인 낭비
    val_hopp_norm(k) = curr_hopp_count * norm_factor;
    
    % 3. Pure UHO (순수 낭비): 전체 UHO - HOPP (남은 낭비)
    val_uho_pure_norm(k) = (curr_uho_count - curr_hopp_count) * norm_factor;
    
    % Total & Wasted Sum 확인
    val_total_norm(k) = val_essential_norm(k) + val_uho_pure_norm(k) + val_hopp_norm(k);
    val_wasted_total_norm(k) = val_uho_pure_norm(k) + val_hopp_norm(k);
end
% 
% 2. 스택 바 차트 데이터 구성 [Essential, Pure UHO, HOPP]
stacked_data = [val_essential_norm', val_uho_pure_norm', val_hopp_norm'];

% 3. 그래프 그리기
b3 = bar(stacked_data, 'stacked', 'BarWidth', 0.6);

% 4. 색상 지정
b3(1).FaceColor = [0.2 0.6 0.2]; % 녹색: Essential
b3(2).FaceColor = [0.8 0.2 0.2]; % 적색: Pure UHO (일반 낭비)
b3(3).FaceColor = [0.5 0.0 0.5]; % 보라색: HOPP (핑퐁 - 악성 낭비)

% 5. 축 및 라벨 설정
ylabel('Average HOs [#/UE/min.]', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'XTick', 1:n_comp, 'XTickLabel', display_names, 'FontSize', 15, 'FontWeight', 'bold');
grid on;

% 범례 (HOPP 추가)
legend({'Essential HO (Valid)', 'Wasted HO (UHO)', 'Wasted HO (HOPP)'}, ...
    'Location', 'northeast', 'FontSize', 15);

% Y축 범위 조정
ylim([0, max(val_total_norm) * 1.35]);

% % 6. 텍스트 라벨 추가 (막대 위)
for k = 1:n_comp
    % (1) 낭비 비율 계산 (UHO + HOPP 전체 기준)
    if val_total_norm(k) > 0
        waste_pct = (val_wasted_total_norm(k) / val_total_norm(k)) * 100;
    else
        waste_pct = 0;
    end

    % (2) 텍스트 표시
    label_str = sprintf('%.1f%%\n Wasted\n(%.1f)', waste_pct, val_total_norm(k));

    if waste_pct == 0
        label_str = sprintf('0%%\n Wasted\n(%.1f)', val_total_norm(k));
    end

    % 위치: 막대 높이 위 (Top)
    text(k, val_total_norm(k) + (max(val_total_norm)*0.02), label_str, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ... 
        'FontSize', 11, 'Color', 'k', 'FontWeight', 'bold');
end

% 결과 저장
savefig(fullfile(output_folder, 'Rev1__SCI_HO_eff.fig'));
saveas(gcf, fullfile(output_folder, 'Rev1__SCI_HO_eff.png'));