% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_plot_final_D2.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.24
% Modified     : 2024.06.24
% =================================================================

%% 서브플롯으로 산점도 그리기 (색깔로 값을 표현)
% 새로운 figure 생성
figure;

% 각 지표에 대한 서브플롯 생성
subplot(3, 2, 1);
scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.final_avg_SINR], 'filled');
xlabel('Thresh1');
ylabel('Thresh2');
title('Normalized SINR');
colorbar;
colormap jet;
grid on;

% subplot(3, 2, 2);
% scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.final_avg_HO], 'filled');
% xlabel('Thresh1');
% ylabel('Thresh2');
% title('Normalized HO');
% colorbar;
% colormap jet;
% grid on;

subplot(3, 2, 2);
scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.final_avg_UHO], 'filled');
xlabel('Thresh1');
ylabel('Thresh2');
title('Normalized UHO');
colorbar;
colormap jet;
grid on;

subplot(3, 2, 3);
scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.final_avg_percent_error_ToS], 'filled');
xlabel('Thresh1');
ylabel('Thresh2');
title('Normalized Percent Error of ToS');
colorbar;
colormap jet;
grid on;

subplot(3, 2, 4);
scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.final_avg_RLF], 'filled');
xlabel('Thresh1');
ylabel('Thresh2');
title('Normalized RLF');
colorbar;
colormap jet;
grid on;

subplot(3, 2, 5);
scatter([scal_new_results.Thresh1], [scal_new_results.Thresh2], 50, [scal_new_results.ObjectiveFunction], 'filled');
xlabel('Thresh1');
ylabel('Thresh2');
title('Normalized ObjectiveFunction');
colorbar;
colormap jet;
grid on;

% 전체 figure 제목 추가
sgtitle('Normalized Performance Metrics for Different TH1 and TH2 Combinations');

% Figure 크기 조정 (선택 사항)
set(gcf, 'Position', [100, 100, 1200, 800]);

%% SIR/ToS PLOT TEST (D2 event, multi UEs and Single TH combinations)
% num_ue = 5;
% 
% figure;
% hold on;
% for combo_idx = 1:num_ue
%     plot(TIMEVECTOR, results.KPI(combo_idx).final_SINR, 'LineWidth', 0.5);
% end
% hold off;
% grid on;
% axis auto;
% title('SINR Variation over Time for Each Combination');
% xlabel('Time');
% ylabel('SINR');
% 
% % Create the legend
% lgd = legend('UE 0', 'UE 10', 'UE 14', 'UE 19', 'UE 23');
% lgd.NumColumns = 5;
% lgd.Location = "south";
% 
% ToS Plotting
% figure;
% hold on;
% for ue_idx = 1:num_ue
%     tos_data = results.KPI(ue_idx).final_avg_percent_error_ToS;
%     bar(ue_idx, tos_data);
% end
% hold off;
% grid on;
% title('Time of Stay (ToS) for Each UE');
% xlabel('UE Index');
% ylabel('Percent Error of Time of Stay');
% xticks(1:num_ue);
% xticklabels({'UE 1', 'UE 2', 'UE 3', 'UE 4', 'UE 5'});
% 
% % UHO Plotting
% figure;
% hold on;
% for ue_idx = 1:num_ue
%     uho_data = results(ue_idx).final_avg_UHO;
%     bar(ue_idx, uho_data);
% end
% hold off;
% grid on;
% title('Unnecessary Handover (UHO) for Each UE');
% xlabel('UE Index');
% ylabel('Number of Unnecessary Handovers');
% xticks(1:num_ue);
% xticklabels({'UE 1', 'UE 2', 'UE 3', 'UE 4', 'UE 5'});

%% Results (NEW, multi UE and Multi TH combinations, avg UE)

%% HEATMAP 그리기
% % TH1과 TH2 값을 x축과 y축으로 사용하고, 내부 값 데이터는 new_results.final_avg_SINR 값 사용
% % 결과 매트릭스 초기화
% heatmap_data = nan(numel(Thresh1_values), numel(Thresh2_values));
% 
% % 각 조합에 대해 데이터를 채움
% for combo_idx = 1:size(combinations, 1)
%     Thresh1 = combinations(combo_idx, 2);
%     Thresh2 = combinations(combo_idx, 3);
% 
%     % 인덱스 계산
%     x_idx = find(Thresh1_values == Thresh1);
%     y_idx = find(Thresh2_values == Thresh2);
% 
%     % 데이터 입력
%     heatmap_data(x_idx, y_idx) = new_results(combo_idx).final_avg_SINR;
% end
% 
% % Heatmap 생성
% figure;
% heatmap(Thresh1_values, Thresh2_values, heatmap_data, 'Colormap', parula);
% xlabel('Thresh2');
% ylabel('Thresh1');
% title('Heatmap of Final Average SINR');

%% 정규화 플롯
% 정규화된 데이터로 그래프 그리기
TH1_values = unique(combinations(:, 2));
TH2_values = unique(combinations(:, 3));
norm_final_avg_SINR_matrix = nan(length(TH1_values), length(TH2_values));
norm_final_avg_HO_matrix = nan(length(TH1_values), length(TH2_values));
norm_final_avg_percent_error_ToS_matrix = nan(length(TH1_values), length(TH2_values));
norm_final_avg_UHO_matrix = nan(length(TH1_values), length(TH2_values));
norm_final_avg_RLF_matrix = nan(length(TH1_values), length(TH2_values));

% 각 조합에 대해 데이터를 채움
for combo_idx = 1:size(combinations, 1)
    Thresh1 = combinations(combo_idx, 2);
    Thresh2 = combinations(combo_idx, 3);

    % 인덱스 계산
    TH1_idx = find(TH1_values == Thresh1);
    TH2_idx = find(TH2_values == Thresh2);

    % 데이터 입력
    norm_final_avg_SINR_matrix(TH1_idx, TH2_idx) = scal_new_results(combo_idx).final_avg_SINR;
    %norm_final_avg_HO_matrix(TH1_idx, TH2_idx) = scal_new_results(combo_idx).final_avg_HO;
    norm_final_avg_percent_error_ToS_matrix(TH1_idx, TH2_idx) = scal_new_results(combo_idx).final_avg_percent_error_ToS;
    norm_final_avg_UHO_matrix(TH1_idx, TH2_idx) = scal_new_results(combo_idx).final_avg_UHO;
    norm_final_avg_RLF_matrix(TH1_idx, TH2_idx) = scal_new_results(combo_idx).final_avg_RLF;
end

% % 3D 서페이스 플롯 생성
% figure;
% 
% subplot(3, 2, 1);
% surf(TH1_values, TH2_values, norm_final_avg_SINR_matrix);
% xlabel('TH1');
% ylabel('TH2');
% zlabel('Normalized Average SINR');
% title('Normalized Average SINR (Higher is Better)');
% colorbar;
% colormap(jet); % Use jet colormap for better visualization
% 
% % subplot(3, 2, 2);
% % surf(TH1_values, TH2_values, norm_final_avg_HO_matrix);
% % xlabel('TH1');
% % ylabel('TH2');
% % zlabel('Normalized Average HO attempt');
% % title('Normalized Average HO attempt (Lower is Better)');
% % colorbar;
% % colormap(jet); % Use jet colormap for better visualization
% 
% subplot(3, 2, 2);
% surf(TH1_values, TH2_values, norm_final_avg_percent_error_ToS_matrix);
% xlabel('TH1');
% ylabel('TH2');
% zlabel('Normalized Average Percent Error of ToS');
% title('Normalized Average Percent Error of ToS (Lower is Better)');
% colorbar;
% colormap(jet); % Use jet colormap for better visualization
% 
% subplot(3, 2, 3);
% surf(TH1_values, TH2_values, norm_final_avg_UHO_matrix);
% xlabel('TH1');
% ylabel('TH2');
% zlabel('Normalized Final Average UHO');
% title('Normalized Final Average UHO (Lower is Better)');
% colorbar;
% colormap(jet); % Use jet colormap for better visualization
% 
% subplot(3, 2, 4);
% surf(TH1_values, TH2_values, norm_final_avg_RLF_matrix);
% xlabel('TH1');
% ylabel('TH2');
% zlabel('Normalized Final Average RLF');
% title('Normalized Final Average RLF (Lower is Better)');
% colorbar;
% colormap(jet); % Use jet colormap for better visualization
% 
% % 전체 figure 제목 추가
% sgtitle('Normalized Performance Metrics for Different TH1 and TH2 Combinations');
% 
% % Figure 크기 조정 (선택 사항)
% set(gcf, 'Position', [100, 100, 1200, 800]);

%% 목적함수 그래프
% 필요한 값들을 추출합니다.
Thresh1_values = [scal_new_results.Thresh1];
Thresh2_values = [scal_new_results.Thresh2];
ObjectiveFunction_values = [scal_new_results.ObjectiveFunction];

% 유일한 Thresh1과 Thresh2 값을 추출합니다.
unique_Thresh1 = unique(Thresh1_values);
unique_Thresh2 = unique(Thresh2_values);

% 행렬을 초기화합니다.
obj_func_matrix = nan(length(unique_Thresh1), length(unique_Thresh2));

% 행렬에 값들을 채워 넣습니다.
for i = 1:length(unique_Thresh1)
    for j = 1:length(unique_Thresh2)
        idx = (Thresh1_values == unique_Thresh1(i)) & (Thresh2_values == unique_Thresh2(j));
        if any(idx)
            obj_func_matrix(i, j) = ObjectiveFunction_values(idx);
        end
    end
end

% 최적의 해를 찾습니다.
[~, optimal_idx] = max(ObjectiveFunction_values);
optimal_Thresh1 = Thresh1_values(optimal_idx);
optimal_Thresh2 = Thresh2_values(optimal_idx);
optimal_obj_func_value = ObjectiveFunction_values(optimal_idx);

%--- 3D surfl 그래프를 생성합니다.
figure;
surfl(unique_Thresh1, unique_Thresh2, obj_func_matrix');  % 행렬을 전치하여 올바르게 플롯합니다.
colormap(pink);    % 색상 맵을 변경합니다.
shading interp;    % 색상 보간을 설정합니다.

% 최적의 해를 강조합니다.
hold on;
scatter3(optimal_Thresh1, optimal_Thresh2, optimal_obj_func_value, 100, 'r', 'filled');
hold off;

% 그래프 속성을 설정합니다.
title('3D Surface Plot of Objective Function Values');
%text(0.4, 0.6,'$\underset{\text{TH1}, \text{TH2}}{\mathrm{argmax}} \ f(\text{TH1}, \text{TH2}) = \alpha \tilde{S} - \beta \tilde{H} - \gamma \tilde{U} - \delta \tilde{R} - \epsilon \tilde{T}$','interpreter','latex','fontsize',15)
xlabel('Thresh1');
ylabel('Thresh2');
zlabel('Objective Function Value');
colorbar;
view(3);