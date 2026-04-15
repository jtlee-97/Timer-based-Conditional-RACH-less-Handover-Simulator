% % =================================================================
% % Winner LAB, Ajou University
% % Distance-based HO Parameter Optimization Protocol Code
% % Prototype    : system_start.m
% % Type         : MATLAB code
% % Author       : Jongtae Lee
% % Revision     : v2.1   2024.06.04
% % Modified     : 2024.08.27
% % =================================================================
% 
% %% SYSTEM_START Script
% clear;
% close all;
% tic;
% 
% %% IMPORT THE FUNCTION CODE FILES
% addpath(genpath('functions'));
% 
% %% SYSTEM PARAMETERS
% run('system_parameter.m');  % system_parameter 실행
% 
% % k_rsrp 값 확인
% if exist('k_rsrp', 'var')
%     k_rsrp_str = sprintf('K%d', k_rsrp);  % 파일명에 들어갈 "~K(i)" 생성
% else
%     k_rsrp_str = '';  % k_rsrp 값이 없으면 추가하지 않음
% end
% 
% % A: BHO (기존 핸드오버, 0dB margin, 0ms TTT)
% % B: BHO (기존 핸드오버, 1dB margin, 100ms TTT)
% % C: BHO (기존 핸드오버, 2dB margin, 256ms TTT)
% % D: CHO (조건부 핸드오버, 0dB margin, 0ms TTT)
% % E: CHO (조건부 핸드오버, 1dB margin, 100ms TTT)
% % F: CHO (조건부 핸드오버, 2dB margin, 256ms TTT)
% % G: DCHO (거리기반 상대조건식, 0m margin, 0ms TTT)
% % H: DCHO (ttt인데 보류)
% % I: DCHO (ttt인데 보류)
% % J: DCHO (3GPP 거리기반 조건부)
% % K: DCHO (최종 제안하는 궤도기반 방안)
% 
% % Initialize strategies and corresponding parameters
% % {strategy_name, strategy_mode, Offset_A3, TTT, choMsgOverride}
% strategies = {
%     % 'Strategy BHO-CFRA', 2, 0, 0, struct();
%     'Strategy CHO-CFRA', 3, 0, 0, struct();
%     'Strategy CHO-CFRA', 3, 1, 100, struct();
%     'Strategy CHO-RAL', 5, 0, 0, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0);
%     'Strategy CHO-RAL', 5, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0);
%     'Strategy A3T1-CHO-RAL', 9, 0, 0, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false);
%     'Strategy A3T1-CHO-RAL', 9, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false);
%     'Strategy A3T1-CHO-RAL(R-2km)', 9, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false,'EXEC_ML_THRESHOLD',cellRadius-2000);
%     'Strategy A3T1-CHO-RAL(R-1km)', 9, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false,'EXEC_ML_THRESHOLD',cellRadius-1000);
%     'Strategy A3T1-CHO-RAL(R+1km)', 9, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false,'EXEC_ML_THRESHOLD',cellRadius+1000);
%     'Strategy A3T1-CHO-RAL(R+2km)', 9, 1, 100, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false,'EXEC_ML_THRESHOLD',cellRadius+2000);
%     %'Strategy D2T1-CHO-RAL', 10, 0, 0, struct('RACHLESS_GRANT_MODE','dynamic','DYN_GRANT_FAIL_ENABLE',false,'DYN_GRANT_FAIL_PROB',0,'DYN_GRANT_PREP_SEND',false);
% };
% 
% for strategy_idx = 1:size(strategies, 1)
%     master_histories_list{strategy_idx} = [];
%     MASTER_SINR = zeros(EPISODE, length(UE_x));
%     MASTER_RSRP = zeros(EPISODE, length(UE_x));
%     MASTER_UHO = zeros(EPISODE, length(UE_x));
%     MASTER_RLF = zeros(EPISODE, length(UE_x));
%     MASTER_HO = zeros(EPISODE, length(UE_x));
%     MASTER_RBs = zeros(EPISODE, length(UE_x));
%     MASTER_HOPP = zeros(EPISODE, length(UE_x));  % HOPP 추가
%     MASTER_MIT_HO_EVENTS = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_T_BREAK = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_T_PROC = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_T_INTERRUPT = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_T_RACH = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_T_HC = zeros(EPISODE, length(UE_x));
%     MASTER_MIT_TOTAL = zeros(EPISODE, length(UE_x));
%     MASTER_RACH_RB_EQ = zeros(EPISODE, length(UE_x));
%     MASTER_DYN_GRANT_TX_COUNT = zeros(EPISODE, length(UE_x));
%     MASTER_DYN_GRANT_FAIL_COUNT = zeros(EPISODE, length(UE_x));
%     MASTER_DYN_GRANT_FALLBACK_COUNT = zeros(EPISODE, length(UE_x));
%     MASTER_ToS = [];  % 1차원 배열로 저장
%     MASTER_RAW_SINR = zeros(length(TIMEVECTOR), length(UE_x));
%     MASTER_RAW_RSRP = zeros(length(TIMEVECTOR), length(UE_x));
% 
%     % Extract current strategy name and parameters
%     strategy_name = strategies{strategy_idx, 1};
%     strategy_mode = strategies{strategy_idx, 2};
%     current_Offset_A3 = strategies{strategy_idx, 3};
%     current_TTT = strategies{strategy_idx, 4};
%     current_cho_override = strategies{strategy_idx, 5};
% 
%     % Loop through each UE_x position
%     for ue_idx = 1:length(UE_x)
%         uex = UE_x(ue_idx);
%         uey = UE_y;
% 
%         % Output progress
%         fprintf('Processing %s, UE position %d of %d\n', strategy_name, ue_idx, length(UE_x));
% 
%         % Run the system process for the current UE position and strategy
%         [histories, episode_results, final_results, master_histories] = system_process(uex, uey, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, strategy_mode, current_Offset_A3, current_TTT, current_cho_override);
%         master_histories_list{strategy_idx} = [master_histories_list{strategy_idx}; master_histories];
% 
%         % Loop through each episode to calculate and store results
%         for episode_idx = 1:EPISODE
%             total_sinr = 0;
%             total_rsrp = 0;
%             for t_idx = 1:length(TIMEVECTOR)
%                 total_sinr = total_sinr + episode_results(1, episode_idx).SINR(t_idx);
%                 total_rsrp = total_rsrp + episode_results(1, episode_idx).RSRP(t_idx);
%             end
% 
%             % Calculate average SINR and store results
%             avg_sinr = total_sinr / length(TIMEVECTOR);
%             avg_rsrp = total_rsrp / length(TIMEVECTOR);
%             MASTER_SINR(episode_idx, ue_idx) = avg_sinr;
%             MASTER_RSRP(episode_idx, ue_idx) = avg_rsrp;
%             MASTER_UHO(episode_idx, ue_idx) = episode_results(1, episode_idx).UHO;
%             MASTER_RLF(episode_idx, ue_idx) = episode_results(1, episode_idx).RLF;
%             MASTER_HO(episode_idx, ue_idx) = episode_results(1, episode_idx).HO;
%             MASTER_RBs(episode_idx, ue_idx) = episode_results(1, episode_idx).RBs;
%             MASTER_HOPP(episode_idx, ue_idx) = episode_results(1, episode_idx).HOPP;
%             MASTER_DYN_GRANT_TX_COUNT(episode_idx, ue_idx) = episode_results(1, episode_idx).DYN_GRANT_TX_COUNT;
%             MASTER_DYN_GRANT_FAIL_COUNT(episode_idx, ue_idx) = episode_results(1, episode_idx).DYN_GRANT_FAIL_COUNT;
%             MASTER_DYN_GRANT_FALLBACK_COUNT(episode_idx, ue_idx) = episode_results(1, episode_idx).DYN_GRANT_FALLBACK_COUNT;
%             MASTER_RACH_RB_EQ(episode_idx, ue_idx) = episode_results(1, episode_idx).RACH_RB_EQ_SUM;
%             ho_events = episode_results(1, episode_idx).MIT_HO_EVENTS;
%             MASTER_MIT_HO_EVENTS(episode_idx, ue_idx) = ho_events;
%             if ho_events > 0
%                 MASTER_MIT_T_BREAK(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_T_BREAK_SUM / ho_events;
%                 MASTER_MIT_T_PROC(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_T_PROC_SUM / ho_events;
%                 MASTER_MIT_T_INTERRUPT(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_T_INTERRUPT_SUM / ho_events;
%                 MASTER_MIT_T_RACH(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_T_RACH_SUM / ho_events;
%                 MASTER_MIT_T_HC(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_T_HC_SUM / ho_events;
%                 MASTER_MIT_TOTAL(episode_idx, ue_idx) = episode_results(1, episode_idx).MIT_TOTAL_SUM / ho_events;
%             else
%                 MASTER_MIT_T_BREAK(episode_idx, ue_idx) = 0;
%                 MASTER_MIT_T_PROC(episode_idx, ue_idx) = 0;
%                 MASTER_MIT_T_INTERRUPT(episode_idx, ue_idx) = 0;
%                 MASTER_MIT_T_RACH(episode_idx, ue_idx) = 0;
%                 MASTER_MIT_T_HC(episode_idx, ue_idx) = 0;
%                 MASTER_MIT_TOTAL(episode_idx, ue_idx) = 0;
%             end
% 
%             % Read the ToS for the current episode
%             tos_values = episode_results(1, episode_idx).ToS;
%             if isempty(tos_values)
%                 tos_values = 0;
%             end
%             if size(tos_values, 1) > 1
%                 tos_values = tos_values';
%             end
%             MASTER_ToS = [MASTER_ToS, tos_values];
%         end
% 
%         % Store final SINR values
%         avg_final_tt_sinr = mean(final_results.final_tt_SINR, 2);
%         avg_final_tt_rsrp = mean(final_results.final_tt_RSRP, 2);
%         MASTER_RAW_SINR(:, ue_idx) = avg_final_tt_sinr;
%         MASTER_RAW_RSRP(:, ue_idx) = avg_final_tt_rsrp;
%         MASTER_RLF_SUM_TEST = sum(MASTER_RLF);
%     end
% 
%     % Save MASTER structure arrays for the current strategy
%     resultsRoot = fullfile(pwd, '/MasterResults');      % 절대경로로 고정 (권장)
%     [outDir,~,~] = fileparts(fullfile(resultsRoot, 'dummy.mat'));
% 
%     % 1) 동일 이름의 "파일"이 존재하면 오류
%     if exist(resultsRoot, 'file') && ~exist(resultsRoot, 'dir')
%         error('A file named "%s" exists. Please delete/rename it.', resultsRoot);
%     end
% 
%     % 2) 폴더 없으면 생성 (상위경로부터 보장)
%     if ~exist(outDir, 'dir')
%         [ok, msg, msgid] = mkdir(outDir);
%         if ~ok
%             error('Failed to create folder "%s": %s (%s)', outDir, msg, msgid);
%         end
%     end
% 
%     % 3) 파일명 구성 (불법문자 방지: \/:*?"<>| 제거)
%     sanitize = @(s) regexprep(s, '[/\\:*?"<>|]', '_');
%     strategy_name_s = sanitize(strategy_name);
%     Scenario_s      = sanitize(Scenario_);
%     fading_s        = sanitize(fading);
%     if isempty(k_rsrp_str), k_rsrp_str = 'K0'; end  % 빈 문자열 방지
% 
% 
%     offset_s = sprintf('A3_%ddB', current_Offset_A3);
%     ttt_s    = sprintf('TTT_%dms', current_TTT);
% 
%     matFileName = fullfile(resultsRoot, ...
%         sprintf('%s_MASTER_RESULTS_%s_%s_%s_%s_%s.mat', Scenario_s, strategy_name_s, offset_s, ttt_s, k_rsrp_str, fading_s));
% 
%     % matFileName = fullfile(resultsRoot, ...
%        % sprintf('%s_MASTER_RESULTS_%s_%s_%s.mat', Scenario_s, strategy_name_s, k_rsrp_str, fading_s));
% 
%     % 4) 저장
%     save(matFileName, 'MASTER_SINR', 'MASTER_RSRP', 'MASTER_UHO', 'MASTER_RLF', ...
%                       'MASTER_HO', 'MASTER_HOPP', 'MASTER_RAW_SINR', 'MASTER_RAW_RSRP', ...
%                       'MASTER_ToS', 'MASTER_RBs', ...
%                       'MASTER_MIT_HO_EVENTS', 'MASTER_MIT_T_BREAK', 'MASTER_MIT_T_PROC', ...
%                       'MASTER_MIT_T_INTERRUPT', 'MASTER_MIT_T_RACH', 'MASTER_MIT_T_HC', 'MASTER_MIT_TOTAL', ...
%                       'MASTER_RACH_RB_EQ', ...
%                       'MASTER_DYN_GRANT_TX_COUNT', 'MASTER_DYN_GRANT_FAIL_COUNT', 'MASTER_DYN_GRANT_FALLBACK_COUNT');
% 
%     fprintf('Saved results -> %s\n', matFileName);
% 
%     % % Save MASTER structure arrays for the current strategy
%     % folderName = 'MasterResults';
%     % if ~exist(folderName, 'dir')
%     %     mkdir(folderName);
%     % end
%     % 
%     % % 파일명에 k_rsrp 값 추가하여 저장
%     % matFileName = fullfile(folderName, [Scenario_, '_MASTER_RESULTS_', strategy_name, '_', k_rsrp_str, '_', fading, '.mat']);
%     % save(matFileName, 'MASTER_SINR', 'MASTER_RSRP', 'MASTER_UHO', 'MASTER_RLF', 'MASTER_HO', 'MASTER_HOPP', 'MASTER_RAW_SINR', 'MASTER_RAW_RSRP', 'MASTER_ToS', 'MASTER_RBs');
% end
% 
% toc;
% 
% if exist('plot_two_latest_results_simple.m', 'file') == 2
%     run('plot_two_latest_results_simple.m');
% else
%     warning('plot_two_latest_results_simple.m not found. Skipping final plot step.');
% end


% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_start.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v2.1   2024.06.04
% Modified     : 2026.03.24
% =================================================================

%% SYSTEM_START Script
clear;
close all;
tic;

%% IMPORT THE FUNCTION CODE FILES
addpath(genpath('functions'));

%% SYSTEM PARAMETERS
run('system_parameter.m');  % system_parameter 실행

% k_rsrp 값 확인
if exist('k_rsrp', 'var')
    k_rsrp_str = sprintf('K%d', k_rsrp);  % 파일명에 들어갈 "~K(i)" 생성
else
    k_rsrp_str = 'K0';  % 기본값
end

% Initialize strategies and corresponding parameters
% {strategy_name, strategy_mode, Offset_A3, TTT, choMsgOverride}
strategies = {
    % 'Strategy BHO-CFRA', 2, 0, 0, struct();
    'Strategy CHO-CFRA', 3, 0, 0, struct();
    'Strategy CHO-CFRA', 3, 1, 0, struct();

    'Strategy CHO-RAL', 5, 0, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0);

    'Strategy CHO-RAL', 5, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0);

    'Strategy A3T1-CHO-RAL', 9, 0, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false);

    'Strategy A3T1-CHO-RAL', 9, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false);

    'Strategy A3T1-CHO-RAL(R-2km)', 9, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false, ...
               'EXEC_ML_THRESHOLD',cellRadius-2000);

    'Strategy A3T1-CHO-RAL(R-1km)', 9, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false, ...
               'EXEC_ML_THRESHOLD',cellRadius-1000);

    'Strategy A3T1-CHO-RAL(R+1km)', 9, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false, ...
               'EXEC_ML_THRESHOLD',cellRadius+1000);

    'Strategy A3T1-CHO-RAL(R+2km)', 9, 1, 0, ...
        struct('RACHLESS_GRANT_MODE','dynamic', ...
               'DYN_GRANT_FAIL_ENABLE',false, ...
               'DYN_GRANT_FAIL_PROB',0, ...
               'DYN_GRANT_PREP_SEND',false, ...
               'EXEC_ML_THRESHOLD',cellRadius+2000);

    % 'Strategy D2T1-CHO-RAL', 10, 0, 0, ...
    %     struct('RACHLESS_GRANT_MODE','dynamic', ...
    %            'DYN_GRANT_FAIL_ENABLE',false, ...
    %            'DYN_GRANT_FAIL_PROB',0, ...
    %            'DYN_GRANT_PREP_SEND',false);
};

for strategy_idx = 1:size(strategies, 1)

    master_histories_list{strategy_idx} = [];

    MASTER_SINR = zeros(EPISODE, length(UE_x));
    MASTER_RSRP = zeros(EPISODE, length(UE_x));
    MASTER_UHO = zeros(EPISODE, length(UE_x));
    MASTER_RLF = zeros(EPISODE, length(UE_x));
    MASTER_HO = zeros(EPISODE, length(UE_x));
    MASTER_RBs = zeros(EPISODE, length(UE_x));
    MASTER_HOPP = zeros(EPISODE, length(UE_x));
    MASTER_MIT_HO_EVENTS = zeros(EPISODE, length(UE_x));
    MASTER_MIT_T_BREAK = zeros(EPISODE, length(UE_x));
    MASTER_MIT_T_PROC = zeros(EPISODE, length(UE_x));
    MASTER_MIT_T_INTERRUPT = zeros(EPISODE, length(UE_x));
    MASTER_MIT_T_RACH = zeros(EPISODE, length(UE_x));
    MASTER_MIT_T_HC = zeros(EPISODE, length(UE_x));
    MASTER_MIT_TOTAL = zeros(EPISODE, length(UE_x));
    MASTER_RACH_RB_EQ = zeros(EPISODE, length(UE_x));
    MASTER_DYN_GRANT_TX_COUNT = zeros(EPISODE, length(UE_x));
    MASTER_DYN_GRANT_FAIL_COUNT = zeros(EPISODE, length(UE_x));
    MASTER_DYN_GRANT_FALLBACK_COUNT = zeros(EPISODE, length(UE_x));
    MASTER_ToS = [];
    MASTER_RAW_SINR = zeros(length(TIMEVECTOR), length(UE_x));
    MASTER_RAW_RSRP = zeros(length(TIMEVECTOR), length(UE_x));

    % Extract current strategy parameters
    base_strategy_name = strategies{strategy_idx, 1};
    strategy_mode = strategies{strategy_idx, 2};
    current_Offset_A3 = strategies{strategy_idx, 3};
    current_TTT = strategies{strategy_idx, 4};
    current_cho_override = strategies{strategy_idx, 5};

    % Expanded strategy name for logging / identification
    strategy_name = sprintf('%s [A3=%gdB,TTT=%dms]', ...
        base_strategy_name, current_Offset_A3, current_TTT);

    % Loop through each UE_x position
    for ue_idx = 1:length(UE_x)
        uex = UE_x(ue_idx);
        uey = UE_y;

        % Output progress
        fprintf('Processing %s, UE position %d of %d\n', ...
            strategy_name, ue_idx, length(UE_x));

        % Run the system process for the current UE position and strategy
        [histories, episode_results, final_results, master_histories] = ...
            system_process(uex, uey, EPISODE, TIMEVECTOR, SITE_MOVE, ...
                           SAMPLE_TIME, strategy_mode, current_Offset_A3, ...
                           current_TTT, current_cho_override);

        master_histories_list{strategy_idx} = ...
            [master_histories_list{strategy_idx}; master_histories];

        % Loop through each episode to calculate and store results
        for episode_idx = 1:EPISODE
            total_sinr = 0;
            total_rsrp = 0;

            for t_idx = 1:length(TIMEVECTOR)
                total_sinr = total_sinr + episode_results(1, episode_idx).SINR(t_idx);
                total_rsrp = total_rsrp + episode_results(1, episode_idx).RSRP(t_idx);
            end

            % Calculate average SINR / RSRP
            avg_sinr = total_sinr / length(TIMEVECTOR);
            avg_rsrp = total_rsrp / length(TIMEVECTOR);

            MASTER_SINR(episode_idx, ue_idx) = avg_sinr;
            MASTER_RSRP(episode_idx, ue_idx) = avg_rsrp;
            MASTER_UHO(episode_idx, ue_idx) = episode_results(1, episode_idx).UHO;
            MASTER_RLF(episode_idx, ue_idx) = episode_results(1, episode_idx).RLF;
            MASTER_HO(episode_idx, ue_idx) = episode_results(1, episode_idx).HO;
            MASTER_RBs(episode_idx, ue_idx) = episode_results(1, episode_idx).RBs;
            MASTER_HOPP(episode_idx, ue_idx) = episode_results(1, episode_idx).HOPP;

            MASTER_DYN_GRANT_TX_COUNT(episode_idx, ue_idx) = ...
                episode_results(1, episode_idx).DYN_GRANT_TX_COUNT;
            MASTER_DYN_GRANT_FAIL_COUNT(episode_idx, ue_idx) = ...
                episode_results(1, episode_idx).DYN_GRANT_FAIL_COUNT;
            MASTER_DYN_GRANT_FALLBACK_COUNT(episode_idx, ue_idx) = ...
                episode_results(1, episode_idx).DYN_GRANT_FALLBACK_COUNT;
            MASTER_RACH_RB_EQ(episode_idx, ue_idx) = ...
                episode_results(1, episode_idx).RACH_RB_EQ_SUM;

            ho_events = episode_results(1, episode_idx).MIT_HO_EVENTS;
            MASTER_MIT_HO_EVENTS(episode_idx, ue_idx) = ho_events;

            if ho_events > 0
                MASTER_MIT_T_BREAK(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_T_BREAK_SUM / ho_events;
                MASTER_MIT_T_PROC(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_T_PROC_SUM / ho_events;
                MASTER_MIT_T_INTERRUPT(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_T_INTERRUPT_SUM / ho_events;
                MASTER_MIT_T_RACH(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_T_RACH_SUM / ho_events;
                MASTER_MIT_T_HC(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_T_HC_SUM / ho_events;
                MASTER_MIT_TOTAL(episode_idx, ue_idx) = ...
                    episode_results(1, episode_idx).MIT_TOTAL_SUM / ho_events;
            else
                MASTER_MIT_T_BREAK(episode_idx, ue_idx) = 0;
                MASTER_MIT_T_PROC(episode_idx, ue_idx) = 0;
                MASTER_MIT_T_INTERRUPT(episode_idx, ue_idx) = 0;
                MASTER_MIT_T_RACH(episode_idx, ue_idx) = 0;
                MASTER_MIT_T_HC(episode_idx, ue_idx) = 0;
                MASTER_MIT_TOTAL(episode_idx, ue_idx) = 0;
            end

            % Read ToS for the current episode
            tos_values = episode_results(1, episode_idx).ToS;
            if isempty(tos_values)
                tos_values = 0;
            end
            if size(tos_values, 1) > 1
                tos_values = tos_values';
            end
            MASTER_ToS = [MASTER_ToS, tos_values];
        end

        % Store final time-series averages
        avg_final_tt_sinr = mean(final_results.final_tt_SINR, 2);
        avg_final_tt_rsrp = mean(final_results.final_tt_RSRP, 2);

        MASTER_RAW_SINR(:, ue_idx) = avg_final_tt_sinr;
        MASTER_RAW_RSRP(:, ue_idx) = avg_final_tt_rsrp;

        MASTER_RLF_SUM_TEST = sum(MASTER_RLF); %#ok<NASGU>
    end

    %% Save MASTER arrays for the current strategy
    resultsRoot = fullfile(pwd, 'MasterResults');
    [outDir,~,~] = fileparts(fullfile(resultsRoot, 'dummy.mat'));

    % 동일 이름의 파일이 이미 있으면 오류
    if exist(resultsRoot, 'file') && ~exist(resultsRoot, 'dir')
        error('A file named "%s" exists. Please delete or rename it.', resultsRoot);
    end

    % 폴더가 없으면 생성
    if ~exist(outDir, 'dir')
        [ok, msg, msgid] = mkdir(outDir);
        if ~ok
            error('Failed to create folder "%s": %s (%s)', outDir, msg, msgid);
        end
    end

    % 파일명 sanitize
    sanitize = @(s) regexprep(s, '[/\\:*?"<>|]', '_');

    strategy_name_s = sanitize(strategy_name);
    Scenario_s = sanitize(Scenario_);
    fading_s = sanitize(fading);

    % Save file name
    matFileName = fullfile(resultsRoot, ...
        sprintf('%s_MASTER_RESULTS_%s_%s_%s.mat', ...
        Scenario_s, strategy_name_s, k_rsrp_str, fading_s));

    % Save
    save(matFileName, ...
        'MASTER_SINR', 'MASTER_RSRP', 'MASTER_UHO', 'MASTER_RLF', ...
        'MASTER_HO', 'MASTER_HOPP', 'MASTER_RAW_SINR', 'MASTER_RAW_RSRP', ...
        'MASTER_ToS', 'MASTER_RBs', ...
        'MASTER_MIT_HO_EVENTS', 'MASTER_MIT_T_BREAK', 'MASTER_MIT_T_PROC', ...
        'MASTER_MIT_T_INTERRUPT', 'MASTER_MIT_T_RACH', 'MASTER_MIT_T_HC', ...
        'MASTER_MIT_TOTAL', 'MASTER_RACH_RB_EQ', ...
        'MASTER_DYN_GRANT_TX_COUNT', 'MASTER_DYN_GRANT_FAIL_COUNT', ...
        'MASTER_DYN_GRANT_FALLBACK_COUNT');

    fprintf('Saved results -> %s\n', matFileName);
end

toc;

if exist('plot_v4_two_latest_results_simple.m', 'file') == 2
    run('plot_v4_two_latest_results_simple.m');
else
    warning('plot_v4_two_latest_results_simple.m not found. Skipping final plot step.');
end