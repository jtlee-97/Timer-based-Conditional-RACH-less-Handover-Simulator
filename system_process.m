% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_process.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v2.2   2025.09.30 (mobility + Th/Tc gate integrated)
% =================================================================

function [histories, episode_results, final_results, master_histories] = system_process(uex, uey, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, option, Offset, TTT, choMsgOverride)
    run('system_parameter.m');

    choMsgCfg = struct();
    choMsgCfg.ENABLE_PROC_DELAY = true;
    choMsgCfg.MIT_INCLUDE_PROCESSING = true;
    choMsgCfg.ENABLE_CTRL_QUEUE = true;
    choMsgCfg.ENABLE_DYN_GRANT_QUEUE = true;
    choMsgCfg.C_LIGHT = 299792458;
    choMsgCfg.PROC_RAND_MIN = 0.010;
    choMsgCfg.PROC_RAND_MAX = 0.016;
    choMsgCfg.PROC_SERV = 0.001;
    choMsgCfg.PROC_TARG = 0.001;
    choMsgCfg.PROC_EXEC_UE = 0.001;
    choMsgCfg.PROC_INTERRUPT = 0.001;
    choMsgCfg.PROC_UE_HC = 0.001;
    choMsgCfg.PROC_GRANT_SCHED = 0.001;
    choMsgCfg.RACHLESS_GRANT_MODE = 'preallocated';
    choMsgCfg.DYN_GRANT_FAIL_ENABLE = true;
    choMsgCfg.DYN_GRANT_FAIL_PROB = 0.15;
    choMsgCfg.DYN_GRANT_FALLBACK_TO_RACH = true;
    choMsgCfg.PROC_FALLBACK_RACH = 0.001;
    choMsgCfg.DYN_GRANT_PERIOD = 0.002;
    choMsgCfg.DYN_GRANT_VALIDITY = 0.01;
    choMsgCfg.DYN_GRANT_MAX_TX = 8;
    choMsgCfg.DYN_GRANT_PREP_SEND = true;
    choMsgCfg.RB_PER_GRANT_TX = 1;
    choMsgCfg.T304 = 0.5;
    choMsgCfg.T310 = 1.0;
    choMsgCfg.DYN_TIMEOUT_ACTION = 'reestablish';
    choMsgCfg.QUEUE_LOG = false;
    choMsgCfg.VERBOSE = false;
    choMsgCfg.DELAY_MODEL_ENABLE = true;
    choMsgCfg.USE_LOSNLOS = true;
    choMsgCfg.APPLY_LOSNLOS_ON_XN = false;
    choMsgCfg.XN_P_LOS = 1.0;
    choMsgCfg.USE_GET_LOSS_TABLE = true;
    choMsgCfg.LOS_TABLE_SCENARIO = 'Rural';
    choMsgCfg.LOS_PROB_A = 9.61;
    choMsgCfg.LOS_PROB_B = 0.16;
    choMsgCfg.LOS_PROB_THETA0 = 9.61;
    choMsgCfg.NLOS_KAPPA_MEAN = 1.20;
    choMsgCfg.NLOS_KAPPA_LN_SIGMA = 0.25;
    choMsgCfg.NLOS_TAU_MEAN = 0.0005;
    choMsgCfg.NLOS_EXCESS_MAX = 0.008;
    if exist('CHO_MSG_C_LIGHT', 'var') && ~isempty(CHO_MSG_C_LIGHT)
        choMsgCfg.C_LIGHT = CHO_MSG_C_LIGHT;
    end
    if exist('CHO_MSG_ENABLE_PROC_DELAY', 'var') && ~isempty(CHO_MSG_ENABLE_PROC_DELAY)
        choMsgCfg.ENABLE_PROC_DELAY = logical(CHO_MSG_ENABLE_PROC_DELAY);
    end
    if exist('CHO_MSG_MIT_INCLUDE_PROCESSING', 'var') && ~isempty(CHO_MSG_MIT_INCLUDE_PROCESSING)
        choMsgCfg.MIT_INCLUDE_PROCESSING = logical(CHO_MSG_MIT_INCLUDE_PROCESSING);
    end
    if exist('CHO_MSG_ENABLE_CTRL_QUEUE', 'var') && ~isempty(CHO_MSG_ENABLE_CTRL_QUEUE)
        choMsgCfg.ENABLE_CTRL_QUEUE = logical(CHO_MSG_ENABLE_CTRL_QUEUE);
    end
    if exist('CHO_MSG_ENABLE_DYN_GRANT_QUEUE', 'var') && ~isempty(CHO_MSG_ENABLE_DYN_GRANT_QUEUE)
        choMsgCfg.ENABLE_DYN_GRANT_QUEUE = logical(CHO_MSG_ENABLE_DYN_GRANT_QUEUE);
    end
    if exist('CHO_MSG_PROC_SERV', 'var') && ~isempty(CHO_MSG_PROC_SERV)
        choMsgCfg.PROC_SERV = CHO_MSG_PROC_SERV;
    end
    if exist('CHO_MSG_PROC_RAND_MIN', 'var') && ~isempty(CHO_MSG_PROC_RAND_MIN)
        choMsgCfg.PROC_RAND_MIN = CHO_MSG_PROC_RAND_MIN;
    end
    if exist('CHO_MSG_PROC_RAND_MAX', 'var') && ~isempty(CHO_MSG_PROC_RAND_MAX)
        choMsgCfg.PROC_RAND_MAX = CHO_MSG_PROC_RAND_MAX;
    end
    if exist('CHO_MSG_PROC_TARG', 'var') && ~isempty(CHO_MSG_PROC_TARG)
        choMsgCfg.PROC_TARG = CHO_MSG_PROC_TARG;
    end
    if exist('CHO_MSG_PROC_EXEC_UE', 'var') && ~isempty(CHO_MSG_PROC_EXEC_UE)
        choMsgCfg.PROC_EXEC_UE = CHO_MSG_PROC_EXEC_UE;
    end
    if exist('CHO_MSG_PROC_INTERRUPT', 'var') && ~isempty(CHO_MSG_PROC_INTERRUPT)
        choMsgCfg.PROC_INTERRUPT = CHO_MSG_PROC_INTERRUPT;
    end
    if exist('CHO_MSG_PROC_UE_HC', 'var') && ~isempty(CHO_MSG_PROC_UE_HC)
        choMsgCfg.PROC_UE_HC = CHO_MSG_PROC_UE_HC;
    end
    if exist('CHO_MSG_PROC_GRANT_SCHED', 'var') && ~isempty(CHO_MSG_PROC_GRANT_SCHED)
        choMsgCfg.PROC_GRANT_SCHED = CHO_MSG_PROC_GRANT_SCHED;
    end
    if exist('CHO_MSG_RACHLESS_GRANT_MODE', 'var') && ~isempty(CHO_MSG_RACHLESS_GRANT_MODE)
        choMsgCfg.RACHLESS_GRANT_MODE = CHO_MSG_RACHLESS_GRANT_MODE;
    end
    if exist('CHO_MSG_DYN_GRANT_FAIL_ENABLE', 'var') && ~isempty(CHO_MSG_DYN_GRANT_FAIL_ENABLE)
        choMsgCfg.DYN_GRANT_FAIL_ENABLE = logical(CHO_MSG_DYN_GRANT_FAIL_ENABLE);
    end
    if exist('CHO_MSG_DYN_GRANT_FAIL_PROB', 'var') && ~isempty(CHO_MSG_DYN_GRANT_FAIL_PROB)
        choMsgCfg.DYN_GRANT_FAIL_PROB = CHO_MSG_DYN_GRANT_FAIL_PROB;
    end
    if exist('CHO_MSG_DYN_GRANT_FALLBACK_TO_RACH', 'var') && ~isempty(CHO_MSG_DYN_GRANT_FALLBACK_TO_RACH)
        choMsgCfg.DYN_GRANT_FALLBACK_TO_RACH = logical(CHO_MSG_DYN_GRANT_FALLBACK_TO_RACH);
    end
    if exist('CHO_MSG_PROC_FALLBACK_RACH', 'var') && ~isempty(CHO_MSG_PROC_FALLBACK_RACH)
        choMsgCfg.PROC_FALLBACK_RACH = CHO_MSG_PROC_FALLBACK_RACH;
    end
    if exist('CHO_MSG_DYN_GRANT_PERIOD', 'var') && ~isempty(CHO_MSG_DYN_GRANT_PERIOD)
        choMsgCfg.DYN_GRANT_PERIOD = CHO_MSG_DYN_GRANT_PERIOD;
    end
    if exist('CHO_MSG_DYN_GRANT_VALIDITY', 'var') && ~isempty(CHO_MSG_DYN_GRANT_VALIDITY)
        choMsgCfg.DYN_GRANT_VALIDITY = CHO_MSG_DYN_GRANT_VALIDITY;
    end
    if exist('CHO_MSG_DYN_GRANT_MAX_TX', 'var') && ~isempty(CHO_MSG_DYN_GRANT_MAX_TX)
        choMsgCfg.DYN_GRANT_MAX_TX = CHO_MSG_DYN_GRANT_MAX_TX;
    end
    if exist('CHO_MSG_DYN_GRANT_PREP_SEND', 'var') && ~isempty(CHO_MSG_DYN_GRANT_PREP_SEND)
        choMsgCfg.DYN_GRANT_PREP_SEND = logical(CHO_MSG_DYN_GRANT_PREP_SEND);
    end
    if exist('CHO_MSG_RB_PER_GRANT_TX', 'var') && ~isempty(CHO_MSG_RB_PER_GRANT_TX)
        choMsgCfg.RB_PER_GRANT_TX = CHO_MSG_RB_PER_GRANT_TX;
    end
    if exist('CHO_MSG_T304', 'var') && ~isempty(CHO_MSG_T304)
        choMsgCfg.T304 = CHO_MSG_T304;
    end
    if exist('CHO_MSG_T310', 'var') && ~isempty(CHO_MSG_T310)
        choMsgCfg.T310 = CHO_MSG_T310;
    end
    if exist('CHO_MSG_DYN_TIMEOUT_ACTION', 'var') && ~isempty(CHO_MSG_DYN_TIMEOUT_ACTION)
        choMsgCfg.DYN_TIMEOUT_ACTION = CHO_MSG_DYN_TIMEOUT_ACTION;
    end
    if exist('CHO_MSG_QUEUE_LOG', 'var') && ~isempty(CHO_MSG_QUEUE_LOG)
        choMsgCfg.QUEUE_LOG = logical(CHO_MSG_QUEUE_LOG);
    end
    if exist('CHO_MSG_VERBOSE', 'var') && ~isempty(CHO_MSG_VERBOSE)
        choMsgCfg.VERBOSE = logical(CHO_MSG_VERBOSE);
    end
    if exist('CHO_MSG_DELAY_MODEL_ENABLE', 'var') && ~isempty(CHO_MSG_DELAY_MODEL_ENABLE)
        choMsgCfg.DELAY_MODEL_ENABLE = logical(CHO_MSG_DELAY_MODEL_ENABLE);
    end
    if exist('CHO_MSG_USE_LOSNLOS', 'var') && ~isempty(CHO_MSG_USE_LOSNLOS)
        choMsgCfg.USE_LOSNLOS = logical(CHO_MSG_USE_LOSNLOS);
    end
    if exist('CHO_MSG_APPLY_LOSNLOS_ON_XN', 'var') && ~isempty(CHO_MSG_APPLY_LOSNLOS_ON_XN)
        choMsgCfg.APPLY_LOSNLOS_ON_XN = logical(CHO_MSG_APPLY_LOSNLOS_ON_XN);
    end
    if exist('CHO_MSG_XN_P_LOS', 'var') && ~isempty(CHO_MSG_XN_P_LOS)
        choMsgCfg.XN_P_LOS = CHO_MSG_XN_P_LOS;
    end
    if exist('CHO_MSG_USE_GET_LOSS_TABLE', 'var') && ~isempty(CHO_MSG_USE_GET_LOSS_TABLE)
        choMsgCfg.USE_GET_LOSS_TABLE = logical(CHO_MSG_USE_GET_LOSS_TABLE);
    end
    if exist('CHO_MSG_LOS_TABLE_SCENARIO', 'var') && ~isempty(CHO_MSG_LOS_TABLE_SCENARIO)
        choMsgCfg.LOS_TABLE_SCENARIO = CHO_MSG_LOS_TABLE_SCENARIO;
    elseif exist('fading', 'var') && ~isempty(fading)
        choMsgCfg.LOS_TABLE_SCENARIO = fading;
    end
    if exist('CHO_MSG_LOS_PROB_A', 'var') && ~isempty(CHO_MSG_LOS_PROB_A)
        choMsgCfg.LOS_PROB_A = CHO_MSG_LOS_PROB_A;
    end
    if exist('CHO_MSG_LOS_PROB_B', 'var') && ~isempty(CHO_MSG_LOS_PROB_B)
        choMsgCfg.LOS_PROB_B = CHO_MSG_LOS_PROB_B;
    end
    if exist('CHO_MSG_LOS_PROB_THETA0', 'var') && ~isempty(CHO_MSG_LOS_PROB_THETA0)
        choMsgCfg.LOS_PROB_THETA0 = CHO_MSG_LOS_PROB_THETA0;
    end
    if exist('CHO_MSG_NLOS_KAPPA_MEAN', 'var') && ~isempty(CHO_MSG_NLOS_KAPPA_MEAN)
        choMsgCfg.NLOS_KAPPA_MEAN = CHO_MSG_NLOS_KAPPA_MEAN;
    end
    if exist('CHO_MSG_NLOS_KAPPA_LN_SIGMA', 'var') && ~isempty(CHO_MSG_NLOS_KAPPA_LN_SIGMA)
        choMsgCfg.NLOS_KAPPA_LN_SIGMA = CHO_MSG_NLOS_KAPPA_LN_SIGMA;
    end
    if exist('CHO_MSG_NLOS_TAU_MEAN', 'var') && ~isempty(CHO_MSG_NLOS_TAU_MEAN)
        choMsgCfg.NLOS_TAU_MEAN = CHO_MSG_NLOS_TAU_MEAN;
    end
    if exist('CHO_MSG_NLOS_EXCESS_MAX', 'var') && ~isempty(CHO_MSG_NLOS_EXCESS_MAX)
        choMsgCfg.NLOS_EXCESS_MAX = CHO_MSG_NLOS_EXCESS_MAX;
    end
    if nargin >= 10 && ~isempty(choMsgOverride) && isstruct(choMsgOverride)
        overrideFields = fieldnames(choMsgOverride);
        for fdx = 1:numel(overrideFields)
            fname = overrideFields{fdx};
            choMsgCfg.(fname) = choMsgOverride.(fname);
        end
    end

    if choMsgCfg.ENABLE_DYN_GRANT_QUEUE
        minValidity = max(SAMPLE_TIME, 0.02);
        if choMsgCfg.DYN_GRANT_VALIDITY < minValidity
            choMsgCfg.DYN_GRANT_VALIDITY = minValidity;
        end

        if choMsgCfg.DYN_GRANT_PERIOD <= 0
            choMsgCfg.DYN_GRANT_PERIOD = minValidity / 4;
        end

        if choMsgCfg.DYN_GRANT_PERIOD > choMsgCfg.DYN_GRANT_VALIDITY
            choMsgCfg.DYN_GRANT_PERIOD = max(1e-4, choMsgCfg.DYN_GRANT_VALIDITY / 2);
        end
    end

    if ~(strcmpi(choMsgCfg.DYN_TIMEOUT_ACTION, 'reestablish') || strcmpi(choMsgCfg.DYN_TIMEOUT_ACTION, 'fallback'))
        choMsgCfg.DYN_TIMEOUT_ACTION = 'fallback';
    end

    if ~isfield(choMsgCfg, 'T310') || isempty(choMsgCfg.T310) || choMsgCfg.T310 <= 0
        choMsgCfg.T310 = 1.0;
    end

    if ~choMsgCfg.ENABLE_PROC_DELAY
        choMsgCfg.PROC_SERV = 0;
        choMsgCfg.PROC_TARG = 0;
        choMsgCfg.PROC_EXEC_UE = 0;
        choMsgCfg.PROC_INTERRUPT = 0;
        choMsgCfg.PROC_UE_HC = 0;
        choMsgCfg.PROC_GRANT_SCHED = 0;
        choMsgCfg.PROC_FALLBACK_RACH = 0;
    end
    
     % === [NEW] Normalize SITE_MOVE to "meters per step" ===
    if exist('SAT_GROUNDSPEED_KMPS','var') && ~isempty(SAT_GROUNDSPEED_KMPS)
        SAT_GROUNDSPEED_MPS = SAT_GROUNDSPEED_KMPS * 1000;   % km/s -> m/s
        SITE_MOVE = SAT_GROUNDSPEED_MPS * SAMPLE_TIME;       % m/step 로 강제 통일
    end

    Hys     = 0;
    if exist('D2_HYS', 'var')
        Hys = D2_HYS;
    end
    d2Thresh2 = cellRadius;
    if exist('D2_THRESH2', 'var')
        d2Thresh2 = D2_THRESH2;
    end
    d2Thresh1Common = 18300;
    if exist('D2_THRESH1', 'var')
        d2Thresh1Common = D2_THRESH1;
    elseif exist('D2_THRESH1_CFRA', 'var')
        d2Thresh1Common = D2_THRESH1_CFRA;
    elseif exist('D2_THRESH1_RACHLESS', 'var')
        d2Thresh1Common = D2_THRESH1_RACHLESS;
    end
    d2Thresh1CFRA = d2Thresh1Common;
    d2Thresh1Rachless = d2Thresh1Common;
    T310    = choMsgCfg.T310;   % RLF 타이머 임계
    % (참고) Thresh1_*, Thresh2는 현재 사용 안함
    Thresh1_1 = cellISD - cellRadius; %#ok<NASGU>
    Thresh1_2 = cellISD/2;            %#ok<NASGU>
    Thresh1_3 = cellRadius;           %#ok<NASGU>
    Thresh2   = cellRadius;           %#ok<NASGU>

    % 객체 생성
    sat      = class_SAT();
    ue_array = [class_UE(uex, uey, 0)];  % 필요시 여러 UE로 확장 가능

    % Data 저장 컨테이너
    histories        = repmat(class_History(),      numel(ue_array), EPISODE);
    episode_results  = repmat(class_EpisodeResult(),numel(ue_array), EPISODE);
    sat_histories    = repmat(struct('BORE_X', [], 'BORE_Y', []), 1, EPISODE);

    %% EPISODE 루프
    idx = 1;
    while idx <= EPISODE
        jdx = 1;

        % SAT/UE 상태 초기화
        sat      = sat.reset_SAT();
        ue_array = RESET_UE(ue_array);

        % === UE 모빌리티 설정 ===
        % 0°=+x, 90°=+y 기준. 여러 UE면 for 루프로 각각 지정.
        ue_array(1) = ue_array(1).set_mobility(200, 0);  % [km/h], [deg]  ← 10 km/h 그대로 입력


        % 위성 위치 히스토리 초기화
        sat_histories(idx).BORE_X = sat.BORE_X;
        sat_histories(idx).BORE_Y = sat.BORE_Y;

        % 초기 상태 업데이트(서빙셀 부여 포함)
        ue_array = UPDATE_UE(sat, ue_array, true, sat_histories, idx);

        %% 시간 스텝 루프
        while jdx <= length(TIMEVECTOR)
            % ---- 1) UE 이동(모빌리티) ----
            for i = 1:numel(ue_array)
                ue_array(i) = ue_array(i).step_move(SAMPLE_TIME);
            end

            % ---- 2) SAT 이동(+y) ----
            sat.BORE_Y = sat.BORE_Y + SITE_MOVE;

            % ---- 3) 시간/히스토리 갱신 ----
            current_time = jdx * SAMPLE_TIME;   % [s]
            sat_histories(idx).BORE_X = [sat_histories(idx).BORE_X; sat.BORE_X];
            sat_histories(idx).BORE_Y = [sat_histories(idx).BORE_Y; sat.BORE_Y];

            % ---- 4) 채널/RSRP/SINR 업데이트 (SERV_SITE_IDX 초기화 제외) ----
            ue_array = UPDATE_UE(sat, ue_array, false, sat_histories, idx);

           % ---- 5) UE별: serving_time 최신화 → Th/Tc 계산 → CHO/RLF ----
            for i = 1:numel(ue_array)
                % 체류시간 시작점 갱신 + Th/Tc는 '그 순간 1회'만 고정 계산
                if ue_array(i).last_site_idx ~= ue_array(i).SERV_SITE_IDX
                    ue_array(i).current_serving_start_time = current_time;
                    ue_array(i).last_site_idx = ue_array(i).SERV_SITE_IDX;
            
                    % === Th/Tc 1회 계산 (units guard 포함) ===
                    serv = ue_array(i).SERV_SITE_IDX;
                    C_xy  = [sat.BORE_X(serv), sat.BORE_Y(serv)];    % center [m, m]
                    UE_xy = [ue_array(i).LOC_X,  ue_array(i).LOC_Y]; % UE    [m, m]
                    R     = cellRadius;
            
                    v_sat_xy = [0, SITE_MOVE / SAMPLE_TIME];  % [m/s] (+y 이동)
                    v_ue_xy  = [ue_array(i).speed_mps*cosd(ue_array(i).heading_deg), ...
                                ue_array(i).speed_mps*sind(ue_array(i).heading_deg)]; % [m/s]
            
                    % ---- UNIT GUARD (모두 meter·second 기준으로 맞춤) ----
                    UE_m = UE_xy; C_m = C_xy; R_m = R; v_sat_m = v_sat_xy; v_ue_m = v_ue_xy;
                    pos_mag = max(abs([UE_xy, C_xy]));
                    if pos_mag < 1e3 && R > 1e3      % 좌표가 km, R은 m처럼 보이면 → 좌표/속도 스케일업
                        UE_m    = UE_xy    * 1e3;
                        C_m     = C_xy     * 1e3;
                        v_sat_m = v_sat_xy * 1e3;
                        v_ue_m  = v_ue_xy  * 1e3;
                    end
                    if pos_mag > 1e3 && R < 1e3      % 좌표가 m, R만 km처럼 보이면 → R만 스케일업
                        R_m = R * 1e3;
                    end
            
                    [Th_fix, Tc_fix, ~] = compute_time_window(UE_m, C_m, R_m, v_sat_m, v_ue_m, true, false);
            
                    % === (신규) 상세 디버그 로그: 실제 좌표·속도·방향 + 수식 중간값 전부 출력 ===
                    log_gate_state( ...
                        current_time, sat, ue_array(i), serv, ...
                        C_xy, UE_xy, R, ...
                        exist('SAT_GROUNDSPEED_KMPS','var') * SAT_GROUNDSPEED_KMPS, ... % 없으면 0 전달
                        SITE_MOVE, SAMPLE_TIME, ...
                        Th_fix, Tc_fix);
            
                    % 게이트 값 저장
                    ue_array(i).Th_gate = Th_fix;              
                    ue_array(i).Tc_gate = Tc_fix;
                    ue_array(i).gate_serv_idx = serv;
                    ue_array(i).gate_ho_completed = false;
            
                    % fprintf('[GATE-SET] t=%.3f: |v_rel|=%.2f, |r0|=%.1f → Th=%.3fs, Tc=%.3fs\n', ...
                    %     current_time, norm(infoWT.v_rel), norm(infoWT.r0), Th_fix, Tc_fix);
                end
            
                ue_array(i).current_serving_time = current_time - ue_array(i).current_serving_start_time;
            
                % --- 시간 게이트 + A3 ---
                switch option
                    case 1
                        ue_array(i) = MTD_A3_BHO(ue_array(i), sat, Offset, TTT, current_time); % BHO A3 (baseline)
                    case 2
                        ue_array(i) = MTD_A3_BHO_CFRA(ue_array(i), sat, Offset, TTT, current_time, choMsgCfg); % BHO-CFRA
                    case 3
                        ue_array(i) = MTD_A3_CHO_rev(ue_array(i), sat, Offset, TTT, current_time, choMsgCfg); % CHO-CFRA
                    case 4
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'preallocated';
                        ue_array(i) = MTD_A3_CHO_rachless(ue_array(i), sat, Offset, TTT, current_time, cfgRachless); % CHO-RACHless (pre-allocated)
                    case 5
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'dynamic';
                        ue_array(i) = MTD_A3_CHO_rachless(ue_array(i), sat, Offset, TTT, current_time, cfgRachless); % CHO-RACHless (dynamic grant)
                    % case 3
                    %     ue_array(i) = MTD_D2_HO_3gpp(ue_array(i), sat, Hys, (cellISD/2), cellRadius, current_time); % Distance
                    case 6   % 게이트 + A3 (기존 TW)
                        ue_array(i) = MTD_TIME_CCNC_CHO( ...
                            ue_array(i), Offset, TTT, current_time, ue_array(i).Th_gate, ue_array(i).Tc_gate); % TW CHO
                    case 7   % D2-CHO-CFRA
                        ue_array(i) = MTD_D2_CHO_CFRA(ue_array(i), sat, Hys, d2Thresh1CFRA, d2Thresh2, current_time, choMsgCfg);
                    case 8   % D2-CHO-RACHless (dynamic grant)
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'dynamic';
                        ue_array(i) = MTD_D2_CHO_rachless(ue_array(i), sat, Hys, d2Thresh1Rachless, d2Thresh2, current_time, cfgRachless);
                    case 9   % A3T1-CHO-RACHless (serving ML 기반 execution + dynamic grant starts at execution)
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'dynamic';
                        cfgRachless.DYN_GRANT_PREP_SEND = false;
                        if ~isfield(cfgRachless, 'EXEC_ML_THRESHOLD') || isempty(cfgRachless.EXEC_ML_THRESHOLD)
                            cfgRachless.EXEC_ML_THRESHOLD = cellRadius;
                        end
                        ue_array(i) = MTD_A3T1_CHO_rachless(ue_array(i), sat, Offset, TTT, current_time, cfgRachless);
                    case 10  % D2T1-CHO-RACHless (D2 prep + serving ML 기반 execution)
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'dynamic';
                        cfgRachless.DYN_GRANT_PREP_SEND = false;
                        cfgRachless.EXEC_ML_THRESHOLD = cellRadius;
                        ue_array(i) = MTD_D2T1_CHO_rachless(ue_array(i), sat, Hys, d2Thresh1Rachless, d2Thresh2, current_time, cfgRachless);
                    case 11  % A3T1D2-CHO-RACHless (A3 prep + single execution event: serving ML only)
                        cfgRachless = choMsgCfg;
                        cfgRachless.RACHLESS_GRANT_MODE = 'dynamic';
                        cfgRachless.DYN_GRANT_PREP_SEND = false;
                        cfgRachless.EXEC_ML_THRESHOLD = cellRadius;
                        cfgRachless.EXEC_SECOND_EVENT_ENABLE = false;
                        ue_array(i) = MTD_A3T1D2_CHO_rachless(ue_array(i), sat, Offset, TTT, current_time, cfgRachless);
                end
            
                % 기존 RLF 체크
                ue_array(i) = ue_array(i).check_RLF(sat, current_time, T310);
            end


            % ---- 6) 히스토리 로깅 ----
            for i = 1:numel(ue_array)
                histories(i, idx) = histories(i, idx).update(ue_array(i));
            end

            jdx = jdx + 1;
        end

        % ---- EPISODE 단위 결과 집계 ----
        for i = 1:numel(ue_array)
            episode_results(i, idx) = episode_results(i, idx).calculate_average(histories(i, idx), SAMPLE_TIME);
        end
        idx = idx + 1;
    end

    % EPISODE 전체 평균(일부 필드) 산출
    master_histories = class_History();
    master_histories.RSRP_dBm = mean(cat(3, histories(:,:).RSRP_dBm), 3, 'omitnan');
    master_histories.LOSS     = mean(cat(3, histories(:,:).LOSS),     3, 'omitnan');

    % 최종 결과 구조
    final_results = repmat(class_FinalResult(), numel(ue_array), 1);
    for i = 1:numel(ue_array)
        final_results(i) = final_results(i).calculate_final_average(episode_results(i, :));
    end
end

% =================================================================
% Helpers (원래 파일 하단 정의 유지)
% =================================================================
function ue_array = RESET_UE(ue_array)
    for i = 1:numel(ue_array)
        ue_array(i).LOC_X = ue_array(i).initial_LOC_X;
        ue_array(i).LOC_Y = ue_array(i).initial_LOC_Y;
        ue_array(i).HO    = 0;
        ue_array(i).RBs   = 0;
        ue_array(i).HOPP  = 0;
        ue_array(i).RLF   = 0;
        ue_array(i).rlf_instance  = [];
        ue_array(i).rlf_indicator = 0;
        ue_array(i).rlf_timer     = 0;
        ue_array(i).handover      = class_Handover(ue_array(i).SERV_SITE_IDX);
        % 체류시간/마지막 셀도 초기화 권장
        ue_array(i).current_serving_start_time = 0;
        ue_array(i).current_serving_time       = 0;
        ue_array(i).last_site_idx              = 0;
        ue_array(i).MIT_HO_EVENTS = 0;
        ue_array(i).MIT_T_BREAK_SUM = 0;
        ue_array(i).MIT_T_PROC_SUM = 0;
        ue_array(i).MIT_T_INTERRUPT_SUM = 0;
        ue_array(i).MIT_T_RACH_SUM = 0;
        ue_array(i).MIT_T_HC_SUM = 0;
        ue_array(i).MIT_TOTAL_SUM = 0;
        ue_array(i).DYN_GRANT_TX_COUNT = 0;
        ue_array(i).DYN_GRANT_FAIL_COUNT = 0;
        ue_array(i).DYN_GRANT_FALLBACK_COUNT = 0;
    end
end

function ue_array = UPDATE_UE(sat, ue_array, is_initial, sat_histories, current_idx) %#ok<INUSD,INUSL>
    run("system_parameter.m");
    num_ues = numel(ue_array);
    for i = 1:num_ues
        % 초기 1회에만 가장 가까운 빔을 서빙으로 설정
        if is_initial
            ue_array(i) = ue_array(i).update_serv_site_idx(sat.BORE_X, sat.BORE_Y);
        end

        % 거리/각도/고도각
        [distances, angles, elevs] = GET_DIS_ANG(sat.BORE_X, sat.BORE_Y, sat.ALTITUDE, ue_array(i).LOC_X, ue_array(i).LOC_Y, ue_array(i).ALTITUDE);
        ue_array(i) = ue_array(i).update_env(distances, angles, elevs);

        % 경로손실/안테나이득/ML/RSRP
        ue_array(i) = ue_array(i).update_loss();
        ue_array(i) = ue_array(i).update_aggain(sat.TX_GAIN);
        ue_array(i) = ue_array(i).update_ml(sat.BORE_X, sat.BORE_Y);
        ue_array(i) = ue_array(i).update_rsrp(sat.TXPW_dBm);

        % 간섭/SINR 전셀 계산
        ue_array(i) = ue_array(i).update_intf_total_all_cells();

        % Xp (시나리오 1)
        ue_array(i) = ue_array(i).update_xp(sat.BORE_X);

        % RSRP Layer-3 필터
        ue_array(i) = ue_array(i).set_filter_coeff(k_rsrp);
        ue_array(i) = ue_array(i).update_rsrp(sat.TXPW_dBm);   % (원 코드 흐름 유지)
        ue_array(i) = ue_array(i).update_rsrp_filtered();
    end
end

function log_gate_state(~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
% 디버그 상세 로그는 필요 시 이 함수 본문에 다시 활성화
% 현재는 기본 실행 성능/가독성을 위해 no-op 유지
    % 
    % fprintf('   r0·v_rel=%.2f, tTCA=%.6f s, d_min=%.3f m, Dt=%.6f s, Tc(formula)=%.6f s\n', ...
    %     rv, tTCA, dmin, Dt, Tc_formula);
    % 
    % fprintf('   ToS (compute_time_window):  Th_hex=%.6f s,  Tc_circ=%.6f s\n', Th_cw, Tc_cw);
    % fprintf('   ToS (gate-set values)   :  Th_set=%.6f s,  Tc_set=%.6f s\n', Th_set, Tc_set);
end
