%% A3-based CHO (RACH-less): execution 후 CFRA 생략, pre-granted UL로 즉시 UL 연결
function ue = MTD_A3_CHO_rachless(ue, sat, Offset_A3, TTT, current_time, msgCfg)
    C_LIGHT = 299792458;
    PROC_SERV = 0.001;
    PROC_TARG = 0.001;
    PROC_EXEC_UE = 0.001;
    PROC_INTERRUPT = 0.001;
    PROC_UE_HC = 0.001;
    PREP_CANCEL_FAIL_MAX = 5;
    MIT_INCLUDE_PROCESSING = false;
    PROC_GRANT_SCHED = 0.001;
    RACHLESS_GRANT_MODE = 'preallocated';
    DYN_GRANT_FAIL_ENABLE = true;
    DYN_GRANT_FAIL_PROB = 0.15;
    DYN_GRANT_FALLBACK_TO_RACH = true;
    PROC_FALLBACK_RACH = 0.001;
    DYN_GRANT_PERIOD = 0.002;
    DYN_GRANT_VALIDITY = 0.01;
    DYN_GRANT_MAX_TX = 8;
    DYN_GRANT_PREP_SEND = true;
    RB_PER_GRANT_TX = 1;
    T304 = 0.5;
    DYN_TIMEOUT_ACTION = 'reestablish';
    ENABLE_PROC_DELAY = true;
    ENABLE_CTRL_QUEUE = true;
    ENABLE_DYN_GRANT_QUEUE = true;
    QUEUE_LOG = false;
    VERBOSE = true;
    DELAY_MODEL_ENABLE = true;
    USE_LOSNLOS = true;
    APPLY_LOSNLOS_ON_XN = false;
    XN_P_LOS = 1.0;
    USE_GET_LOSS_TABLE = true;
    LOS_TABLE_SCENARIO = 'Rural';
    LOS_PROB_A = 9.61;
    LOS_PROB_B = 0.16;
    LOS_PROB_THETA0 = 9.61;
    NLOS_KAPPA_MEAN = 1.20;
    NLOS_KAPPA_LN_SIGMA = 0.25;
    NLOS_TAU_MEAN = 0.0005;
    NLOS_EXCESS_MAX = 0.008;

    if nargin >= 6 && ~isempty(msgCfg)
        if isfield(msgCfg, 'C_LIGHT') && ~isempty(msgCfg.C_LIGHT)
            C_LIGHT = msgCfg.C_LIGHT;
        end
        if isfield(msgCfg, 'PROC_SERV') && ~isempty(msgCfg.PROC_SERV)
            PROC_SERV = msgCfg.PROC_SERV;
        end
        if isfield(msgCfg, 'PROC_TARG') && ~isempty(msgCfg.PROC_TARG)
            PROC_TARG = msgCfg.PROC_TARG;
        end
        if isfield(msgCfg, 'PROC_EXEC_UE') && ~isempty(msgCfg.PROC_EXEC_UE)
            PROC_EXEC_UE = msgCfg.PROC_EXEC_UE;
        end
        if isfield(msgCfg, 'PROC_INTERRUPT') && ~isempty(msgCfg.PROC_INTERRUPT)
            PROC_INTERRUPT = msgCfg.PROC_INTERRUPT;
        end
        if isfield(msgCfg, 'PROC_UE_HC') && ~isempty(msgCfg.PROC_UE_HC)
            PROC_UE_HC = msgCfg.PROC_UE_HC;
        end
        if isfield(msgCfg, 'MIT_INCLUDE_PROCESSING') && ~isempty(msgCfg.MIT_INCLUDE_PROCESSING)
            MIT_INCLUDE_PROCESSING = logical(msgCfg.MIT_INCLUDE_PROCESSING);
        end
        if isfield(msgCfg, 'PROC_GRANT_SCHED') && ~isempty(msgCfg.PROC_GRANT_SCHED)
            PROC_GRANT_SCHED = msgCfg.PROC_GRANT_SCHED;
        end
        if isfield(msgCfg, 'RACHLESS_GRANT_MODE') && ~isempty(msgCfg.RACHLESS_GRANT_MODE)
            RACHLESS_GRANT_MODE = msgCfg.RACHLESS_GRANT_MODE;
        end
        if isfield(msgCfg, 'DYN_GRANT_FAIL_ENABLE') && ~isempty(msgCfg.DYN_GRANT_FAIL_ENABLE)
            DYN_GRANT_FAIL_ENABLE = logical(msgCfg.DYN_GRANT_FAIL_ENABLE);
        end
        if isfield(msgCfg, 'DYN_GRANT_FAIL_PROB') && ~isempty(msgCfg.DYN_GRANT_FAIL_PROB)
            DYN_GRANT_FAIL_PROB = msgCfg.DYN_GRANT_FAIL_PROB;
        end
        if isfield(msgCfg, 'DYN_GRANT_FALLBACK_TO_RACH') && ~isempty(msgCfg.DYN_GRANT_FALLBACK_TO_RACH)
            DYN_GRANT_FALLBACK_TO_RACH = logical(msgCfg.DYN_GRANT_FALLBACK_TO_RACH);
        end
        if isfield(msgCfg, 'PROC_FALLBACK_RACH') && ~isempty(msgCfg.PROC_FALLBACK_RACH)
            PROC_FALLBACK_RACH = msgCfg.PROC_FALLBACK_RACH;
        end
        if isfield(msgCfg, 'DYN_GRANT_PERIOD') && ~isempty(msgCfg.DYN_GRANT_PERIOD)
            DYN_GRANT_PERIOD = msgCfg.DYN_GRANT_PERIOD;
        end
        if isfield(msgCfg, 'DYN_GRANT_VALIDITY') && ~isempty(msgCfg.DYN_GRANT_VALIDITY)
            DYN_GRANT_VALIDITY = msgCfg.DYN_GRANT_VALIDITY;
        end
        if isfield(msgCfg, 'DYN_GRANT_MAX_TX') && ~isempty(msgCfg.DYN_GRANT_MAX_TX)
            DYN_GRANT_MAX_TX = msgCfg.DYN_GRANT_MAX_TX;
        end
        if isfield(msgCfg, 'DYN_GRANT_PREP_SEND') && ~isempty(msgCfg.DYN_GRANT_PREP_SEND)
            DYN_GRANT_PREP_SEND = logical(msgCfg.DYN_GRANT_PREP_SEND);
        end
        if isfield(msgCfg, 'RB_PER_GRANT_TX') && ~isempty(msgCfg.RB_PER_GRANT_TX)
            RB_PER_GRANT_TX = msgCfg.RB_PER_GRANT_TX;
        end
        if isfield(msgCfg, 'T304') && ~isempty(msgCfg.T304)
            T304 = msgCfg.T304;
        end
        if isfield(msgCfg, 'DYN_TIMEOUT_ACTION') && ~isempty(msgCfg.DYN_TIMEOUT_ACTION)
            DYN_TIMEOUT_ACTION = msgCfg.DYN_TIMEOUT_ACTION;
        end
        if isfield(msgCfg, 'ENABLE_PROC_DELAY') && ~isempty(msgCfg.ENABLE_PROC_DELAY)
            ENABLE_PROC_DELAY = logical(msgCfg.ENABLE_PROC_DELAY);
        end
        if isfield(msgCfg, 'ENABLE_CTRL_QUEUE') && ~isempty(msgCfg.ENABLE_CTRL_QUEUE)
            ENABLE_CTRL_QUEUE = logical(msgCfg.ENABLE_CTRL_QUEUE);
        end
        if isfield(msgCfg, 'ENABLE_DYN_GRANT_QUEUE') && ~isempty(msgCfg.ENABLE_DYN_GRANT_QUEUE)
            ENABLE_DYN_GRANT_QUEUE = logical(msgCfg.ENABLE_DYN_GRANT_QUEUE);
        end
        if isfield(msgCfg, 'QUEUE_LOG') && ~isempty(msgCfg.QUEUE_LOG)
            QUEUE_LOG = logical(msgCfg.QUEUE_LOG);
        end
        if isfield(msgCfg, 'VERBOSE') && ~isempty(msgCfg.VERBOSE)
            VERBOSE = logical(msgCfg.VERBOSE);
        end
        if isfield(msgCfg, 'DELAY_MODEL_ENABLE') && ~isempty(msgCfg.DELAY_MODEL_ENABLE)
            DELAY_MODEL_ENABLE = logical(msgCfg.DELAY_MODEL_ENABLE);
        end
        if isfield(msgCfg, 'USE_LOSNLOS') && ~isempty(msgCfg.USE_LOSNLOS)
            USE_LOSNLOS = logical(msgCfg.USE_LOSNLOS);
        end
        if isfield(msgCfg, 'APPLY_LOSNLOS_ON_XN') && ~isempty(msgCfg.APPLY_LOSNLOS_ON_XN)
            APPLY_LOSNLOS_ON_XN = logical(msgCfg.APPLY_LOSNLOS_ON_XN);
        end
        if isfield(msgCfg, 'XN_P_LOS') && ~isempty(msgCfg.XN_P_LOS)
            XN_P_LOS = msgCfg.XN_P_LOS;
        end
        if isfield(msgCfg, 'USE_GET_LOSS_TABLE') && ~isempty(msgCfg.USE_GET_LOSS_TABLE)
            USE_GET_LOSS_TABLE = logical(msgCfg.USE_GET_LOSS_TABLE);
        end
        if isfield(msgCfg, 'LOS_TABLE_SCENARIO') && ~isempty(msgCfg.LOS_TABLE_SCENARIO)
            LOS_TABLE_SCENARIO = msgCfg.LOS_TABLE_SCENARIO;
        end
        if isfield(msgCfg, 'LOS_PROB_A') && ~isempty(msgCfg.LOS_PROB_A)
            LOS_PROB_A = msgCfg.LOS_PROB_A;
        end
        if isfield(msgCfg, 'LOS_PROB_B') && ~isempty(msgCfg.LOS_PROB_B)
            LOS_PROB_B = msgCfg.LOS_PROB_B;
        end
        if isfield(msgCfg, 'LOS_PROB_THETA0') && ~isempty(msgCfg.LOS_PROB_THETA0)
            LOS_PROB_THETA0 = msgCfg.LOS_PROB_THETA0;
        end
        if isfield(msgCfg, 'NLOS_KAPPA_MEAN') && ~isempty(msgCfg.NLOS_KAPPA_MEAN)
            NLOS_KAPPA_MEAN = msgCfg.NLOS_KAPPA_MEAN;
        end
        if isfield(msgCfg, 'NLOS_KAPPA_LN_SIGMA') && ~isempty(msgCfg.NLOS_KAPPA_LN_SIGMA)
            NLOS_KAPPA_LN_SIGMA = msgCfg.NLOS_KAPPA_LN_SIGMA;
        end
        if isfield(msgCfg, 'NLOS_TAU_MEAN') && ~isempty(msgCfg.NLOS_TAU_MEAN)
            NLOS_TAU_MEAN = msgCfg.NLOS_TAU_MEAN;
        end
        if isfield(msgCfg, 'NLOS_EXCESS_MAX') && ~isempty(msgCfg.NLOS_EXCESS_MAX)
            NLOS_EXCESS_MAX = msgCfg.NLOS_EXCESS_MAX;
        end
    end

    delayCfg = struct();
    delayCfg.C_LIGHT = C_LIGHT;
    delayCfg.DELAY_MODEL_ENABLE = DELAY_MODEL_ENABLE;
    delayCfg.USE_LOSNLOS = USE_LOSNLOS;
    delayCfg.APPLY_LOSNLOS_ON_XN = APPLY_LOSNLOS_ON_XN;
    delayCfg.XN_P_LOS = XN_P_LOS;
    delayCfg.USE_GET_LOSS_TABLE = USE_GET_LOSS_TABLE;
    delayCfg.LOS_TABLE_SCENARIO = LOS_TABLE_SCENARIO;
    delayCfg.LOS_PROB_A = LOS_PROB_A;
    delayCfg.LOS_PROB_B = LOS_PROB_B;
    delayCfg.LOS_PROB_THETA0 = LOS_PROB_THETA0;
    delayCfg.NLOS_KAPPA_MEAN = NLOS_KAPPA_MEAN;
    delayCfg.NLOS_KAPPA_LN_SIGMA = NLOS_KAPPA_LN_SIGMA;
    delayCfg.NLOS_TAU_MEAN = NLOS_TAU_MEAN;
    delayCfg.NLOS_EXCESS_MAX = NLOS_EXCESS_MAX;

    ue = ensure_rrc_proc_samples(ue, ENABLE_PROC_DELAY, msgCfg);
    PROC_SERV = ue.handover.proc_serv_evt;
    PROC_TARG = ue.handover.proc_targ_evt;
    PROC_EXEC_UE = ue.handover.proc_exec_ue_evt;
    PROC_INTERRUPT = ue.handover.proc_interrupt_evt;
    PROC_UE_HC = ue.handover.proc_ue_hc_evt;
    PROC_GRANT_SCHED = ue.handover.proc_grant_sched_evt;
    PROC_FALLBACK_RACH = ue.handover.proc_fallback_rach_evt;

    handover = ue.handover;
    serv = ue.SERV_SITE_IDX;

    cond1_vec = ue.RSRP_FILTERED > (ue.RSRP_FILTERED(serv) + Offset_A3);
    cond1_vec(serv) = false;

    cond2_t_enter = false;
    if handover.targ_idx > 0
        cond2_t_enter = ue.RSRP_FILTERED(handover.targ_idx) > (ue.RSRP_FILTERED(serv) + Offset_A3);
    end

    if ~handover.preparation_state && ~handover.execution_state
        if any(cond1_vec)
            ue.RBs = ue.RBs + 1;

            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
            end

            valid_indices = find(cond1_vec);
            [~, max_idx] = max(ue.RSRP_FILTERED(valid_indices));
            new_site_idx = valid_indices(max_idx);

            if new_site_idx ~= serv && (current_time - ue.handover.TTT_check) >= TTT
                ue.handover = ue.handover.initiate_preparation(current_time, new_site_idx);

                serv_xy = [sat.BORE_X(serv), sat.BORE_Y(serv)];
                targ_xy = [sat.BORE_X(new_site_idx), sat.BORE_Y(new_site_idx)];
                ue_xy = [ue.LOC_X, ue.LOC_Y];
                sat_alt = get_sat_altitude(sat);

                [pd_serv_targ, ~] = pd_3d_model(serv_xy, sat_alt, targ_xy, sat_alt, delayCfg, 'XN');
                [pd_serv_ue, ~] = pd_3d_model(serv_xy, sat_alt, ue_xy, ue.ALTITUDE, delayCfg, 'UE');

                ue.handover.ho_req_tx_time = current_time;
                ue.handover.ho_req_rx_time = ue.handover.ho_req_tx_time + pd_serv_targ;
                ue.handover.ho_req_ack_tx_time = ue.handover.ho_req_rx_time + PROC_TARG;
                ue.handover.ho_req_ack_rx_time = ue.handover.ho_req_ack_tx_time + pd_serv_targ;
                ue.handover.cho_cmd_tx_time = ue.handover.ho_req_ack_rx_time + PROC_SERV;
                ue.handover.cho_cmd_rx_time = ue.handover.cho_cmd_tx_time + pd_serv_ue;
                if ENABLE_CTRL_QUEUE
                    ue.handover = ue.handover.clear_control_queue();
                    ue.handover = ue.handover.enqueue_control_msg("MR_RX", current_time, current_time + pd_serv_ue, inf, struct('serv', serv));
                    ue.handover = ue.handover.enqueue_control_msg("HO_REQ_RX", ue.handover.ho_req_tx_time, ue.handover.ho_req_rx_time, inf, struct('targ', new_site_idx));
                    ue.handover = ue.handover.enqueue_control_msg("HO_REQ_ACK_RX", ue.handover.ho_req_ack_tx_time, ue.handover.ho_req_ack_rx_time, inf, struct('serv', serv));
                    ue.handover = ue.handover.enqueue_control_msg("CHO_CMD_RX", ue.handover.cho_cmd_tx_time, ue.handover.cho_cmd_rx_time, inf, struct('targ', new_site_idx));
                    queue_log_print(QUEUE_LOG, current_time, 'CTRL-ENQ-PREP', ue.handover.control_msg_queue, 'mr/ho-req/ack/cmd queued');
                end

                dt_ho_req_s = ue.handover.ho_req_rx_time - ue.handover.ho_req_tx_time;
                dt_ho_req_ack_s = ue.handover.ho_req_ack_rx_time - ue.handover.ho_req_ack_tx_time;
                dt_cho_cmd_s = ue.handover.cho_cmd_rx_time - ue.handover.cho_cmd_tx_time;

                ue.handover.msg_phase = "WAIT_CHO_CMD_RX";
                ue.handover.msg_due_time = ue.handover.cho_cmd_rx_time;

                ue.RBs = ue.RBs + 2;

                if VERBOSE
                    fprintf('[CHO-PREP][RACHLESS] t=%.6f: serv=%d, targ=%d, TTT=%.3f met\n', current_time, serv, new_site_idx, TTT);
                    fprintf('  [HO-REQ]      TX=%.6f, RX=%.6f, elapsed=%.6f s (%.3f ms)\n', ue.handover.ho_req_tx_time, ue.handover.ho_req_rx_time, dt_ho_req_s, dt_ho_req_s*1e3);
                    fprintf('  [HO-REQ-ACK]  TX=%.6f, RX=%.6f, elapsed=%.6f s (%.3f ms)\n', ue.handover.ho_req_ack_tx_time, ue.handover.ho_req_ack_rx_time, dt_ho_req_ack_s, dt_ho_req_ack_s*1e3);
                    fprintf('  [CHO-CMD]     TX=%.6f, RX=%.6f, elapsed=%.6f s (%.3f ms)\n', ue.handover.cho_cmd_tx_time, ue.handover.cho_cmd_rx_time, dt_cho_cmd_s, dt_cho_cmd_s*1e3);
                    if strcmpi(strtrim(RACHLESS_GRANT_MODE), 'preallocated')
                        prealloc_done_t = ue.handover.ho_req_ack_rx_time + PROC_TARG;
                        fprintf('  [PRE-GRANT]   pre-allocated during preparation at t=%.6f\n', prealloc_done_t);
                    else
                        fprintf('  [DYN-GRANT]   grant will be requested after execution (no pre-allocation)\n');
                    end
                end
            end
        else
            ue.handover.TTT_check = 0;
        end

        return;
    end

    if handover.preparation_state
        targ = handover.targ_idx;
        if targ <= 0
            ue.handover = ue.handover.reset(serv);
            return;
        end

        targ_xy = [sat.BORE_X(targ), sat.BORE_Y(targ)];
        ue_xy = [ue.LOC_X, ue.LOC_Y];
        sat_alt = get_sat_altitude(sat);
        [pd_ue_targ, ~] = pd_3d_model(ue_xy, ue.ALTITUDE, targ_xy, sat_alt, delayCfg, 'UE');
        pd_targ_ue = pd_ue_targ;

        if strcmpi(strtrim(RACHLESS_GRANT_MODE), 'dynamic') && ENABLE_DYN_GRANT_QUEUE
            ue = enqueue_dynamic_grants(ue, current_time, pd_targ_ue, PROC_GRANT_SCHED, DYN_GRANT_PERIOD, ...
                DYN_GRANT_VALIDITY, DYN_GRANT_MAX_TX, RB_PER_GRANT_TX, DYN_GRANT_PREP_SEND, PROC_INTERRUPT, QUEUE_LOG);
            ue = prune_dynamic_grant_queue(ue, current_time);
        end

        if ue.handover.msg_phase == "WAIT_CHO_CMD_RX"
            if ENABLE_CTRL_QUEUE
                [ue.handover, msg, hasMsg] = ue.handover.pop_due_control_msg(current_time, "CHO_CMD_RX");
                if ~hasMsg
                    return;
                end
                ue.handover.cho_cmd_rx_time = msg.arrival_time;
                queue_log_print(QUEUE_LOG, current_time, 'CTRL-POP-CMD', ue.handover.control_msg_queue, 'cmd received');
            else
                if current_time < ue.handover.cho_cmd_rx_time
                    return;
                end
            end
            ue.handover.msg_phase = "CMD_RX_DONE";
            ue.handover.msg_due_time = current_time;
            if VERBOSE
                fprintf('[CHO-CMD-RX][RACHLESS] t=%.6f: UE received CHO command for targ=%d\n', current_time, targ);
            end
        end

        if ~cond2_t_enter
            ue.handover.prep_cond_fail_count = ue.handover.prep_cond_fail_count + 1;
            if ue.handover.prep_cond_fail_count >= PREP_CANCEL_FAIL_MAX
                ue.handover.exec_TTT_check = 0;
                ue.handover = ue.handover.reset(serv);
                if VERBOSE
                    fprintf('[CHO-CANCEL][RACHLESS] t=%.6f: cond2 failed %d consecutive times after prep, reset to serv=%d\n', current_time, PREP_CANCEL_FAIL_MAX, serv);
                end
            end
            return;
        end

        ue.handover.prep_cond_fail_count = 0;

        if ue.handover.exec_TTT_check == 0
            ue.handover.exec_TTT_check = ue.handover.cho_cmd_rx_time;
        end

        exec_ready_time = ue.handover.exec_TTT_check + PROC_EXEC_UE;
        if current_time < exec_ready_time
            if strcmpi(strtrim(RACHLESS_GRANT_MODE), 'dynamic') && ENABLE_DYN_GRANT_QUEUE
                queue_log_print(QUEUE_LOG, current_time, 'PRE-EXEC-DROP', ue.handover.dynamic_grant_queue, 'execution not ready');
                ue = drop_all_dynamic_grants(ue);
            end
            return;
        end

        if ue.handover.msg_phase == "CMD_RX_DONE" && ~ue.handover.execution_state
            exec_time_evt = max(exec_ready_time, ue.handover.cho_cmd_rx_time);
            ue.handover = ue.handover.initiate_execution(exec_time_evt);
            ue.handover.mit_detach_time = NaN;
            ue.handover.used_rach_fallback = false;

            t_break = 0;
            t_proc = 0;

            grantMode = lower(strtrim(RACHLESS_GRANT_MODE));
            if strcmp(grantMode, 'dynamic')
                if ~ENABLE_DYN_GRANT_QUEUE
                    ul_tx = ue.handover.exec_time + PROC_UE_HC;
                    ul_rx = ul_tx + pd_ue_targ;
                    ue.handover.mit_detach_time = ue.handover.exec_time;
                    ue.MIT_T_BREAK_SUM = ue.MIT_T_BREAK_SUM + t_break;
                    ue.MIT_T_PROC_SUM = ue.MIT_T_PROC_SUM + t_proc;
                    ue.handover.cfra_preamble_tx_time = ul_tx;
                    ue.handover.cfra_preamble_rx_time = ul_tx;
                    ue.handover.cfra_rsp_tx_time = ul_tx;
                    ue.handover.cfra_rsp_rx_time = ul_tx;
                    ue.handover.ho_complete_tx_time = ul_tx;
                    ue.handover.ho_complete_rx_time = ul_rx;
                    if ENABLE_CTRL_QUEUE
                        ue.handover = ue.handover.enqueue_control_msg("HO_COMPLETE_RX", ue.handover.ho_complete_tx_time, ue.handover.ho_complete_rx_time, inf, struct('targ', targ));
                        queue_log_print(QUEUE_LOG, current_time, 'CTRL-ENQ-HOC', ue.handover.control_msg_queue, 'ho complete queued');
                    end
                    ue.handover.msg_phase = "WAIT_HO_COMPLETE_RX";
                    ue.handover.msg_due_time = ue.handover.ho_complete_rx_time;
                    return;
                end
                ue.MIT_T_BREAK_SUM = ue.MIT_T_BREAK_SUM + t_break;
                ue.MIT_T_PROC_SUM = ue.MIT_T_PROC_SUM + t_proc;
                ue.handover.cfra_preamble_tx_time = ue.handover.exec_time;
                ue.handover.cfra_preamble_rx_time = ue.handover.exec_time;
                ue.handover.dyn_grant_deadline = ue.handover.exec_time + max(0, T304);
                ue.handover.msg_phase = "WAIT_DYN_GRANT";
                ue.handover.msg_due_time = ue.handover.dyn_grant_deadline;
                queue_log_print(QUEUE_LOG, current_time, 'POST-EXEC-WAIT', ue.handover.dynamic_grant_queue, 'waiting grant pop');
                return;
            else
                % Pre-allocated grant: preparation phase에서 UL grant 완료, execution 후 즉시 UL 송신
                ul_tx = ue.handover.exec_time + PROC_UE_HC;
                ul_rx = ul_tx + pd_ue_targ;
                ue.handover.mit_detach_time = ue.handover.exec_time;

                ue.handover.cfra_preamble_tx_time = ul_tx;
                ue.handover.cfra_preamble_rx_time = ul_tx;
                ue.handover.cfra_rsp_tx_time = ul_tx;
                ue.handover.cfra_rsp_rx_time = ul_tx;
            end

            ue.MIT_T_BREAK_SUM = ue.MIT_T_BREAK_SUM + t_break;
            ue.MIT_T_PROC_SUM = ue.MIT_T_PROC_SUM + t_proc;

            ue.handover.ho_complete_tx_time = ul_tx;
            ue.handover.ho_complete_rx_time = ul_rx;
            ue.handover.msg_phase = "WAIT_HO_COMPLETE_RX";
            ue.handover.msg_due_time = ue.handover.ho_complete_rx_time;

            if VERBOSE
                dt_hc_msg = ue.handover.ho_complete_rx_time - ue.handover.ho_complete_tx_time;
                if ~strcmp(grantMode, 'dynamic')
                    fprintf('[RACHLESS-UL-LINK][PREALLOC] t=%.6f: targ=%d, pre-granted UL used\n', ue.handover.exec_time, targ);
                end
                fprintf('  [MIT] T_break=%.6f s (%.3f ms), T_proc=%.6f s (%.3f ms), T_interrupt=%.6f s (%.3f ms)\n', ...
                    t_break, t_break*1e3, t_proc, t_proc*1e3, max(0, PROC_INTERRUPT), max(0, PROC_INTERRUPT)*1e3);
                fprintf('  [HO-COMPLETE-MSG] TX=%.6f, RX=%.6f, elapsed=%.6f s (%.3f ms)\n', ...
                    ue.handover.ho_complete_tx_time, ue.handover.ho_complete_rx_time, dt_hc_msg, dt_hc_msg*1e3);
            end
            return;
        end

        if ue.handover.msg_phase == "WAIT_DYN_GRANT"
            ue = prune_dynamic_grant_queue(ue, current_time);
            queue_log_print(QUEUE_LOG, current_time, 'WAIT-DYN', ue.handover.dynamic_grant_queue, 'queue pruned');

            if current_time > ue.handover.dyn_grant_deadline
                ue.DYN_GRANT_FAIL_COUNT = ue.DYN_GRANT_FAIL_COUNT + 1;
                if DYN_GRANT_FALLBACK_TO_RACH && strcmpi(strtrim(DYN_TIMEOUT_ACTION), 'fallback')
                    ue.handover.used_rach_fallback = true;
                    ue.DYN_GRANT_FALLBACK_COUNT = ue.DYN_GRANT_FALLBACK_COUNT + 1;
                    cfra_tx = current_time + PROC_FALLBACK_RACH;
                    cfra_rx = cfra_tx + pd_ue_targ;
                    cfra_rsp_tx = cfra_rx + PROC_TARG;
                    cfra_rsp_rx = cfra_rsp_tx + pd_ue_targ;
                    ue.handover.mit_detach_time = cfra_tx;
                    ue.handover.cfra_preamble_tx_time = cfra_tx;
                    ue.handover.cfra_preamble_rx_time = cfra_rx;
                    ue.handover.cfra_rsp_tx_time = cfra_rsp_tx;
                    ue.handover.cfra_rsp_rx_time = cfra_rsp_rx;
                else
                    if VERBOSE
                        fprintf('[RACHLESS-DYN][T304-EXPIRE] t=%.6f: dynamic grant queue timed out\n', current_time);
                    end
                    ue.RLF = ue.RLF + 1;
                    ue.handover = ue.handover.reset(serv);
                    return;
                end
            else
                [ue, grantMsg, hasGrant] = pop_latest_valid_grant(ue, current_time);
                if ~hasGrant
                    queue_log_print(QUEUE_LOG, current_time, 'POP-MISS', ue.handover.dynamic_grant_queue, 'no valid grant');
                    return;
                end

                grantDecodeFail = DYN_GRANT_FAIL_ENABLE && (rand() < min(max(DYN_GRANT_FAIL_PROB, 0), 1));
                if grantDecodeFail
                    ue.DYN_GRANT_FAIL_COUNT = ue.DYN_GRANT_FAIL_COUNT + 1;
                    queue_log_print(QUEUE_LOG, current_time, 'POP-DECODE-FAIL', ue.handover.dynamic_grant_queue, 'grant dropped');
                    if VERBOSE
                        fprintf('[RACHLESS-DYN][DECODE-FAIL] t=%.6f: dropped one grant from queue\n', current_time);
                    end
                    return;
                end

                ul_tx = max(current_time, grantMsg.arrival_time) + PROC_UE_HC;
                ul_rx = ul_tx + pd_ue_targ;
                ue.handover.mit_detach_time = ue.handover.exec_time;
                ue.handover.cfra_preamble_tx_time = ul_tx;
                ue.handover.cfra_preamble_rx_time = ul_tx;
                ue.handover.cfra_rsp_tx_time = ul_tx;
                ue.handover.cfra_rsp_rx_time = ul_tx;

                if VERBOSE
                    fprintf('[RACHLESS-UL-LINK][DYNAMIC-QUEUE] t=%.6f: consumed queued grant (tx=%.6f, arr=%.6f)\n', ...
                        current_time, grantMsg.tx_time, grantMsg.arrival_time);
                end
                queue_log_print(QUEUE_LOG, current_time, 'POP-SUCCESS', ue.handover.dynamic_grant_queue, sprintf('used tx=%.6f arr=%.6f', grantMsg.tx_time, grantMsg.arrival_time));
            end

            if ue.handover.used_rach_fallback
                ue.handover.ho_complete_tx_time = ue.handover.cfra_rsp_rx_time + PROC_UE_HC;
                ue.handover.ho_complete_rx_time = ue.handover.ho_complete_tx_time + pd_ue_targ;
            else
                ue.handover.ho_complete_tx_time = ul_tx;
                ue.handover.ho_complete_rx_time = ul_rx;
            end
            if ENABLE_CTRL_QUEUE
                ue.handover = ue.handover.enqueue_control_msg("HO_COMPLETE_RX", ue.handover.ho_complete_tx_time, ue.handover.ho_complete_rx_time, inf, struct('targ', targ));
            end
            ue.handover.msg_phase = "WAIT_HO_COMPLETE_RX";
            ue.handover.msg_due_time = ue.handover.ho_complete_rx_time;
            if ENABLE_CTRL_QUEUE
                queue_log_print(QUEUE_LOG, current_time, 'CTRL-ENQ-HOC', ue.handover.control_msg_queue, 'ho complete queued');
            end
            return;
        end

        if ue.handover.msg_phase == "WAIT_HO_COMPLETE_RX"
            if ENABLE_CTRL_QUEUE
                [ue.handover, msg, hasMsg] = ue.handover.pop_due_control_msg(current_time, "HO_COMPLETE_RX");
                if ~hasMsg
                    return;
                end
                ue.handover.ho_complete_rx_time = msg.arrival_time;
                queue_log_print(QUEUE_LOG, current_time, 'CTRL-POP-HOC', ue.handover.control_msg_queue, 'ho complete rx');
            else
                if current_time < ue.handover.ho_complete_rx_time
                    return;
                end
            end

            old_serv = ue.SERV_SITE_IDX;
            ue.SERV_SITE_IDX = targ;
            ue.current_serving_start_time = current_time;
            ue.current_serving_time = 0;
            ue.HO = ue.HO + 1;
            if ue.handover.used_rach_fallback
                ue.RBs = ue.RBs + 6 + 1;
            else
                ue.RBs = ue.RBs + 1;
            end

            t_rach = max(0, ue.handover.cfra_rsp_rx_time - ue.handover.cfra_preamble_tx_time);
            t_hc = max(0, ue.handover.ho_complete_rx_time - ue.handover.cfra_rsp_rx_time);
            detach_time_evt = ue.handover.mit_detach_time;
            if isnan(detach_time_evt)
                detach_time_evt = ue.handover.exec_time;
            end
            if ue.handover.used_rach_fallback
                t_mit_raw = max(0, ue.handover.ho_complete_rx_time - detach_time_evt);
                proc_in_mit = max(0, PROC_FALLBACK_RACH) + max(0, PROC_TARG) + max(0, PROC_UE_HC);
                if MIT_INCLUDE_PROCESSING
                    t_mit_total = t_mit_raw;
                else
                    t_mit_total = max(0, t_mit_raw - proc_in_mit);
                end
            else
                if MIT_INCLUDE_PROCESSING
                    t_mit_total = max(0, PROC_UE_HC + pd_ue_targ);
                else
                    t_mit_total = max(0, pd_ue_targ);
                end
            end
            ue.MIT_T_RACH_SUM = ue.MIT_T_RACH_SUM + t_rach;
            ue.MIT_T_HC_SUM = ue.MIT_T_HC_SUM + t_hc;
            ue.MIT_TOTAL_SUM = ue.MIT_TOTAL_SUM + t_mit_total;
            if ue.handover.used_rach_fallback
                ue.RACH_RB_EQ_SUM = ue.RACH_RB_EQ_SUM + 6;
            end
            ue.MIT_HO_EVENTS = ue.MIT_HO_EVENTS + 1;

            if VERBOSE
                fprintf('[HO-COMPLETE][RACHLESS] t=%.6f: serv %d -> %d (HO=%d)\n', current_time, old_serv, targ, ue.HO);
                fprintf('  [MIT] T_rach=%.6f s (%.3f ms), T_HC=%.6f s (%.3f ms), MIT_total(HO)=%.6f s (%.3f ms)\n', ...
                    t_rach, t_rach*1e3, t_hc, t_hc*1e3, ...
                    (ue.MIT_TOTAL_SUM / max(1, ue.MIT_HO_EVENTS)), ...
                    ((ue.MIT_TOTAL_SUM / max(1, ue.MIT_HO_EVENTS))*1e3));
                fprintf('  [MIT_DIRECT] detach@DETACH_TS -> attach@HO-COMPLETE-RX = %.3f ms\n', t_mit_total*1e3);
            end
            ue.handover = ue.handover.reset(targ);
            return;
        end
    end
end

function ue = enqueue_dynamic_grants(ue, current_time, pd_targ_ue, proc_grant_sched, grant_period, grant_validity, max_tx_per_step, rb_per_grant, prep_send, proc_interrupt, queueLog)
    hand = ue.handover;
    if isnan(hand.ho_req_ack_tx_time)
        return;
    end

    period = max(grant_period, 1e-6);
    validity = max(grant_validity, period);

    if isnan(hand.dyn_grant_next_tx_time)
        if prep_send
            stream_start = hand.ho_req_ack_tx_time + proc_grant_sched;
        else
            if ~hand.execution_state
                return;
            end
            stream_start = hand.exec_time + proc_interrupt + pd_targ_ue + proc_grant_sched;
        end
        hand.dyn_grant_next_tx_time = stream_start + rand() * period;
    end

    if hand.dyn_grant_next_tx_time > current_time
        ue.handover = hand;
        return;
    end

    created = 0;
    txCap = max(1, round(max_tx_per_step));
    while hand.dyn_grant_next_tx_time <= current_time && created < txCap
        tx_t = hand.dyn_grant_next_tx_time;
        arr_t = tx_t + pd_targ_ue;
        exp_t = arr_t + validity;
        hand.dynamic_grant_queue(end+1) = struct('arrival_time', arr_t, 'expiry_time', exp_t, 'tx_time', tx_t); %#ok<AGROW>
        created = created + 1;
        hand.dyn_grant_next_tx_time = hand.dyn_grant_next_tx_time + period;
    end

    if hand.dyn_grant_next_tx_time <= current_time
        skipN = floor((current_time - hand.dyn_grant_next_tx_time) / period) + 1;
        hand.dyn_grant_next_tx_time = hand.dyn_grant_next_tx_time + skipN * period;
    end

    ue.handover = hand;
    ue.DYN_GRANT_TX_COUNT = ue.DYN_GRANT_TX_COUNT + created;
    ue.RBs = ue.RBs + created * max(0, rb_per_grant);
    if created > 0
        queue_log_print(queueLog, current_time, 'ENQUEUE', hand.dynamic_grant_queue, sprintf('created=%d', created));
    end
end

function ue = prune_dynamic_grant_queue(ue, current_time)
    q = ue.handover.dynamic_grant_queue;
    if isempty(q)
        return;
    end
    keep = [q.expiry_time] >= current_time;
    ue.handover.dynamic_grant_queue = q(keep);
end

function ue = drop_all_dynamic_grants(ue)
    ue.handover.dynamic_grant_queue = struct('arrival_time', {}, 'expiry_time', {}, 'tx_time', {});
end

function [ue, grantMsg, hasGrant] = pop_latest_valid_grant(ue, current_time)
    grantMsg = struct('arrival_time', NaN, 'expiry_time', NaN, 'tx_time', NaN);
    hasGrant = false;
    q = ue.handover.dynamic_grant_queue;
    if isempty(q)
        return;
    end

    validIdx = find([q.arrival_time] <= current_time & [q.expiry_time] >= current_time);
    if isempty(validIdx)
        return;
    end

    [~, local] = max([q(validIdx).arrival_time]);
    pick = validIdx(local);
    grantMsg = q(pick);
    hasGrant = true;

    q(pick) = [];
    ue.handover.dynamic_grant_queue = q;
end

function queue_log_print(enableLog, current_time, tag, queueData, extra)
    if ~enableLog
        return;
    end
    qlen = numel(queueData);
    if qlen > 0
        lastArr = queueData(end).arrival_time;
        lastExp = queueData(end).expiry_time;
        fprintf('[QUEUE][%s] t=%.6f len=%d last(arr=%.6f, exp=%.6f) %s\n', tag, current_time, qlen, lastArr, lastExp, extra);
    else
        fprintf('[QUEUE][%s] t=%.6f len=0 %s\n', tag, current_time, extra);
    end
end

function alt = get_sat_altitude(sat)
    alt = 0;
    if isprop(sat, 'ALTITUDE') && ~isempty(sat.ALTITUDE)
        alt = sat.ALTITUDE;
    end
end

function delay = pd_3d(xy1, z1, xy2, z2, c)
    d = sqrt((xy1(1)-xy2(1))^2 + (xy1(2)-xy2(2))^2 + (z1-z2)^2);
    delay = d / c;
end

function [delay, detail] = pd_3d_model(xy1, z1, xy2, z2, cfg, linkType)
    c = cfg.C_LIGHT;
    d3 = sqrt((xy1(1)-xy2(1))^2 + (xy1(2)-xy2(2))^2 + (z1-z2)^2);
    baseDelay = pd_3d(xy1, z1, xy2, z2, c);

    detail = struct('isLOS', true, 'pLOS', 1.0, 'baseDelay', baseDelay, 'excessDelay', 0.0);

    if ~cfg.DELAY_MODEL_ENABLE
        delay = baseDelay;
        return;
    end

    if ~cfg.USE_LOSNLOS
        delay = baseDelay;
        return;
    end

    if strcmpi(linkType, 'XN')
        if ~cfg.APPLY_LOSNLOS_ON_XN
            delay = baseDelay;
            return;
        end
        pLOS = min(max(cfg.XN_P_LOS, 0), 1);
    else
        d2 = sqrt((xy1(1)-xy2(1))^2 + (xy1(2)-xy2(2))^2);
        elevDeg = atand(abs(z1 - z2) / max(d2, 1e-9));
        if cfg.USE_GET_LOSS_TABLE
            pLOS = los_prob_from_get_loss_table(elevDeg, cfg.LOS_TABLE_SCENARIO) / 100;
        else
            pLOS = 1 / (1 + cfg.LOS_PROB_A * exp(-cfg.LOS_PROB_B * (elevDeg - cfg.LOS_PROB_THETA0)));
        end
        pLOS = min(max(pLOS, 0), 1);
    end

    isLOS = (rand() <= pLOS);
    detail.isLOS = isLOS;
    detail.pLOS = pLOS;

    if isLOS
        delay = baseDelay;
        return;
    end

    sigma = max(cfg.NLOS_KAPPA_LN_SIGMA, 0);
    mu = log(max(cfg.NLOS_KAPPA_MEAN, 1.0)) - 0.5 * sigma^2;
    kappa = exp(mu + sigma * randn());
    kappa = max(kappa, 1.0);

    u = max(rand(), 1e-12);
    tauMp = -max(cfg.NLOS_TAU_MEAN, 0) * log(u);
    excessGeom = ((kappa - 1.0) * d3) / c;
    excess = excessGeom + tauMp;
    excess = min(max(excess, 0), max(cfg.NLOS_EXCESS_MAX, 0));

    detail.excessDelay = excess;
    delay = baseDelay + excess;
end

function p = los_prob_from_get_loss_table(elevDeg, scenario)
    idx = max(1, min(round(elevDeg / 10), 9));
    if isstring(scenario)
        scenario = char(scenario);
    end
    switch lower(strtrim(scenario))
        case 'urban'
            tbl = [24.6 38.6 49.3 61.3 72.6 80.5 91.9 96.8 99.2];
        case {'denseurban','dense urban'}
            tbl = [28.2 33.1 39.8 46.8 53.7 61.2 73.8 82.0 98.1];
        otherwise
            tbl = [78.2 86.9 91.9 92.9 93.5 94.0 94.9 95.2 99.8];
    end
    p = tbl(idx);
end
