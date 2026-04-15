function ue = ensure_rrc_proc_samples(ue, enableProcDelay, msgCfg)
    if nargin < 2 || isempty(enableProcDelay)
        enableProcDelay = true;
    end
    if nargin < 3 || isempty(msgCfg)
        msgCfg = struct();
    end

    procRandMin = 0.010;
    procRandMax = 0.016;

    if isfield(msgCfg, 'PROC_RAND_MIN') && ~isempty(msgCfg.PROC_RAND_MIN)
        procRandMin = msgCfg.PROC_RAND_MIN;
    end
    if isfield(msgCfg, 'PROC_RAND_MAX') && ~isempty(msgCfg.PROC_RAND_MAX)
        procRandMax = msgCfg.PROC_RAND_MAX;
    end

    procRandMin = max(0, procRandMin);
    procRandMax = max(0, procRandMax);
    if procRandMax < procRandMin
        tmp = procRandMin;
        procRandMin = procRandMax;
        procRandMax = tmp;
    end

    if enableProcDelay
        sampleDelay = @() (procRandMin + (procRandMax - procRandMin) * rand());
    else
        sampleDelay = @() 0;
    end

    hand = ue.handover;

    if isnan(hand.proc_serv_evt)
        hand.proc_serv_evt = sampleDelay();
    end
    if isnan(hand.proc_targ_evt)
        hand.proc_targ_evt = sampleDelay();
    end
    if isnan(hand.proc_exec_ue_evt)
        hand.proc_exec_ue_evt = sampleDelay();
    end
    if isnan(hand.proc_interrupt_evt)
        hand.proc_interrupt_evt = sampleDelay();
    end
    if isnan(hand.proc_ue_hc_evt)
        hand.proc_ue_hc_evt = sampleDelay();
    end
    if isnan(hand.proc_grant_sched_evt)
        hand.proc_grant_sched_evt = sampleDelay();
    end
    if isnan(hand.proc_fallback_rach_evt)
        hand.proc_fallback_rach_evt = sampleDelay();
    end

    ue.handover = hand;
end
