function ue = MTD_A3T1D2_CHO_rachless(ue, sat, Offset_A3, TTT, current_time, msgCfg)
% A3T1D2-CHO-RACHless:
% - Preparation: A3-based CHO preparation
% - Execution: single event only (serving ML >= threshold)
% - No 2nd execution-time A3 re-evaluation

    if nargin < 6 || isempty(msgCfg)
        msgCfg = struct();
    end

    msgCfg.EXEC_SECOND_EVENT_ENABLE = false;
    ue = MTD_A3T1_CHO_rachless(ue, sat, Offset_A3, TTT, current_time, msgCfg);
end
