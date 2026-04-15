%% A3-based BHO with CFRA procedure and MIT decomposition
function ue = MTD_A3_BHO_CFRA(ue, sat, Offset_A3, TTT, current_time, msgCfg)
    C_LIGHT = 299792458;
    PROC_TARG = 0.001;
    PROC_EXEC_UE = 0.001;
    PROC_INTERRUPT = 0.001;
    PROC_UE_HC = 0.001;
    ENABLE_PROC_DELAY = true;
    MIT_INCLUDE_PROCESSING = false;
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
        if isfield(msgCfg, 'C_LIGHT') && ~isempty(msgCfg.C_LIGHT), C_LIGHT = msgCfg.C_LIGHT; end
        if isfield(msgCfg, 'PROC_TARG') && ~isempty(msgCfg.PROC_TARG), PROC_TARG = msgCfg.PROC_TARG; end
        if isfield(msgCfg, 'PROC_EXEC_UE') && ~isempty(msgCfg.PROC_EXEC_UE), PROC_EXEC_UE = msgCfg.PROC_EXEC_UE; end
        if isfield(msgCfg, 'PROC_INTERRUPT') && ~isempty(msgCfg.PROC_INTERRUPT), PROC_INTERRUPT = msgCfg.PROC_INTERRUPT; end
        if isfield(msgCfg, 'PROC_UE_HC') && ~isempty(msgCfg.PROC_UE_HC), PROC_UE_HC = msgCfg.PROC_UE_HC; end
        if isfield(msgCfg, 'ENABLE_PROC_DELAY') && ~isempty(msgCfg.ENABLE_PROC_DELAY), ENABLE_PROC_DELAY = logical(msgCfg.ENABLE_PROC_DELAY); end
        if isfield(msgCfg, 'MIT_INCLUDE_PROCESSING') && ~isempty(msgCfg.MIT_INCLUDE_PROCESSING), MIT_INCLUDE_PROCESSING = logical(msgCfg.MIT_INCLUDE_PROCESSING); end
        if isfield(msgCfg, 'VERBOSE') && ~isempty(msgCfg.VERBOSE), VERBOSE = logical(msgCfg.VERBOSE); end

        if isfield(msgCfg, 'DELAY_MODEL_ENABLE') && ~isempty(msgCfg.DELAY_MODEL_ENABLE), DELAY_MODEL_ENABLE = logical(msgCfg.DELAY_MODEL_ENABLE); end
        if isfield(msgCfg, 'USE_LOSNLOS') && ~isempty(msgCfg.USE_LOSNLOS), USE_LOSNLOS = logical(msgCfg.USE_LOSNLOS); end
        if isfield(msgCfg, 'APPLY_LOSNLOS_ON_XN') && ~isempty(msgCfg.APPLY_LOSNLOS_ON_XN), APPLY_LOSNLOS_ON_XN = logical(msgCfg.APPLY_LOSNLOS_ON_XN); end
        if isfield(msgCfg, 'XN_P_LOS') && ~isempty(msgCfg.XN_P_LOS), XN_P_LOS = msgCfg.XN_P_LOS; end
        if isfield(msgCfg, 'USE_GET_LOSS_TABLE') && ~isempty(msgCfg.USE_GET_LOSS_TABLE), USE_GET_LOSS_TABLE = logical(msgCfg.USE_GET_LOSS_TABLE); end
        if isfield(msgCfg, 'LOS_TABLE_SCENARIO') && ~isempty(msgCfg.LOS_TABLE_SCENARIO), LOS_TABLE_SCENARIO = msgCfg.LOS_TABLE_SCENARIO; end
        if isfield(msgCfg, 'LOS_PROB_A') && ~isempty(msgCfg.LOS_PROB_A), LOS_PROB_A = msgCfg.LOS_PROB_A; end
        if isfield(msgCfg, 'LOS_PROB_B') && ~isempty(msgCfg.LOS_PROB_B), LOS_PROB_B = msgCfg.LOS_PROB_B; end
        if isfield(msgCfg, 'LOS_PROB_THETA0') && ~isempty(msgCfg.LOS_PROB_THETA0), LOS_PROB_THETA0 = msgCfg.LOS_PROB_THETA0; end
        if isfield(msgCfg, 'NLOS_KAPPA_MEAN') && ~isempty(msgCfg.NLOS_KAPPA_MEAN), NLOS_KAPPA_MEAN = msgCfg.NLOS_KAPPA_MEAN; end
        if isfield(msgCfg, 'NLOS_KAPPA_LN_SIGMA') && ~isempty(msgCfg.NLOS_KAPPA_LN_SIGMA), NLOS_KAPPA_LN_SIGMA = msgCfg.NLOS_KAPPA_LN_SIGMA; end
        if isfield(msgCfg, 'NLOS_TAU_MEAN') && ~isempty(msgCfg.NLOS_TAU_MEAN), NLOS_TAU_MEAN = msgCfg.NLOS_TAU_MEAN; end
        if isfield(msgCfg, 'NLOS_EXCESS_MAX') && ~isempty(msgCfg.NLOS_EXCESS_MAX), NLOS_EXCESS_MAX = msgCfg.NLOS_EXCESS_MAX; end
    end

    delayCfg = struct('C_LIGHT', C_LIGHT, 'DELAY_MODEL_ENABLE', DELAY_MODEL_ENABLE, 'USE_LOSNLOS', USE_LOSNLOS, ...
        'APPLY_LOSNLOS_ON_XN', APPLY_LOSNLOS_ON_XN, 'XN_P_LOS', XN_P_LOS, 'USE_GET_LOSS_TABLE', USE_GET_LOSS_TABLE, ...
        'LOS_TABLE_SCENARIO', LOS_TABLE_SCENARIO, 'LOS_PROB_A', LOS_PROB_A, 'LOS_PROB_B', LOS_PROB_B, ...
        'LOS_PROB_THETA0', LOS_PROB_THETA0, 'NLOS_KAPPA_MEAN', NLOS_KAPPA_MEAN, ...
        'NLOS_KAPPA_LN_SIGMA', NLOS_KAPPA_LN_SIGMA, 'NLOS_TAU_MEAN', NLOS_TAU_MEAN, 'NLOS_EXCESS_MAX', NLOS_EXCESS_MAX);

    ue = ensure_rrc_proc_samples(ue, ENABLE_PROC_DELAY, msgCfg);
    PROC_TARG = ue.handover.proc_targ_evt;
    PROC_EXEC_UE = ue.handover.proc_exec_ue_evt;
    PROC_INTERRUPT = ue.handover.proc_interrupt_evt;
    PROC_UE_HC = ue.handover.proc_ue_hc_evt;

    handover = ue.handover;
    serv = ue.SERV_SITE_IDX;

    cond1_vec = ue.RSRP_FILTERED > (ue.RSRP_FILTERED(serv) + Offset_A3);
    cond1_vec(serv) = false;

    if any(cond1_vec)
        if handover.TTT_check == 0
            ue.handover.TTT_check = current_time;
        end

        valid_indices = find(cond1_vec);
        [~, max_idx] = max(ue.RSRP_FILTERED(valid_indices));
        targ = valid_indices(max_idx);

        if targ ~= serv && (current_time - ue.handover.TTT_check) >= TTT
            ue.handover = ue.handover.initiate_execution(current_time);

            targ_xy = [sat.BORE_X(targ), sat.BORE_Y(targ)];
            serv_xy = [sat.BORE_X(serv), sat.BORE_Y(serv)];
            ue_xy = [ue.LOC_X, ue.LOC_Y];
            sat_alt = get_sat_altitude(sat);
            [pd_ue_targ, ~] = pd_3d_model(ue_xy, ue.ALTITUDE, targ_xy, sat_alt, delayCfg, 'UE');
            [pd_serv_ue, ~] = pd_3d_model(serv_xy, sat_alt, ue_xy, ue.ALTITUDE, delayCfg, 'UE');

            ho_cmd_tx = current_time;
            ho_cmd_rx = ho_cmd_tx + pd_serv_ue;

            t_break = 0;
            t_proc = max(0, PROC_EXEC_UE);
            t_interrupt = max(0, PROC_INTERRUPT);

            cfra_tx = ho_cmd_rx + t_proc + t_interrupt;
            cfra_rx = cfra_tx + pd_ue_targ;
            cfra_rsp_tx = cfra_rx + PROC_TARG;
            cfra_rsp_rx = cfra_rsp_tx + pd_ue_targ;

            ho_complete_tx = cfra_rsp_rx + PROC_UE_HC;
            ho_complete_rx = ho_complete_tx + pd_ue_targ;

            ue.handover.cfra_preamble_tx_time = cfra_tx;
            ue.handover.cfra_preamble_rx_time = cfra_rx;
            ue.handover.cfra_rsp_tx_time = cfra_rsp_tx;
            ue.handover.cfra_rsp_rx_time = cfra_rsp_rx;
            ue.handover.ho_complete_tx_time = ho_complete_tx;
            ue.handover.ho_complete_rx_time = ho_complete_rx;
            ue.handover.mit_detach_time = ho_cmd_rx;

            t_rach = max(0, cfra_rsp_rx - cfra_tx);
            t_hc = max(0, ho_complete_rx - cfra_rsp_rx);
            t_mit_raw = max(0, ho_complete_rx - ue.handover.mit_detach_time);
            proc_in_mit = max(0, PROC_EXEC_UE) + max(0, PROC_INTERRUPT) + max(0, PROC_TARG) + max(0, PROC_UE_HC);
            if MIT_INCLUDE_PROCESSING
                t_mit_total = t_mit_raw;
            else
                t_mit_total = max(0, t_mit_raw - proc_in_mit);
            end

            ue.MIT_T_BREAK_SUM = ue.MIT_T_BREAK_SUM + t_break;
            ue.MIT_T_PROC_SUM = ue.MIT_T_PROC_SUM + t_proc;
            ue.MIT_T_INTERRUPT_SUM = ue.MIT_T_INTERRUPT_SUM + t_interrupt;
            ue.MIT_T_RACH_SUM = ue.MIT_T_RACH_SUM + t_rach;
            ue.MIT_T_HC_SUM = ue.MIT_T_HC_SUM + t_hc;
            ue.MIT_TOTAL_SUM = ue.MIT_TOTAL_SUM + t_mit_total;
            ue.RACH_RB_EQ_SUM = ue.RACH_RB_EQ_SUM + 6;
            ue.MIT_HO_EVENTS = ue.MIT_HO_EVENTS + 1;

            ue.SERV_SITE_IDX = targ;
            ue.current_serving_start_time = current_time;
            ue.current_serving_time = 0;
            ue.HO = ue.HO + 1;
            ue.RBs = ue.RBs + 1 + 2 + 6 + 1;
            ue.handover = ue.handover.reset(targ);

            if VERBOSE
                fprintf('[BHO-CFRA] t=%.6f: serv=%d -> targ=%d (HO=%d)\n', current_time, serv, targ, ue.HO);
                fprintf('  [MIT] T_break=%.3fms, T_proc=%.3fms, T_interrupt=%.3fms, T_rach=%.3fms, T_HC=%.3fms\n', ...
                    t_break*1e3, t_proc*1e3, t_interrupt*1e3, t_rach*1e3, t_hc*1e3);
                fprintf('  [MIT_DIRECT] detach@HO-CMD-RX -> attach@HO-COMPLETE-RX = %.3f ms\n', t_mit_total*1e3);
            end
        end
    else
        ue.handover.TTT_check = 0;
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
    if ~cfg.DELAY_MODEL_ENABLE || ~cfg.USE_LOSNLOS
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
    excess = min(max(excessGeom + tauMp, 0), max(cfg.NLOS_EXCESS_MAX, 0));
    detail.excessDelay = excess;
    delay = baseDelay + excess;
end

function p = los_prob_from_get_loss_table(elevDeg, scenario)
    idx = max(1, min(round(elevDeg / 10), 9));
    if isstring(scenario), scenario = char(scenario); end
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
