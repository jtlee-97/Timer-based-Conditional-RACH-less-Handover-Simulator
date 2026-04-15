% =================================================================
% Winner LAB, Ajou University
% Handover Class Definition
% Prototype    : class_Handover.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.1   2024.08.29  % 날짜 수정
% Modified     : 2024.08.29  % 수정 날짜 업데이트
% =================================================================

% classdef class_Handover
%     properties
%         preparation_state;
%         execution_state;
%         prep_time;
%         exec_time;
%         serv_idx;
%         targ_idx;
%         TTT_check;
%         exec_TTT_check;
%         last_ho_time;
%         last_site_idx;
%         Xp_locked;
%         Xp_locked_next;
%         PD_check;  % 전파 지연 타이머 속성 추가
%         valid_indices;  % 필터링된 후보 셀 인덱스
%     end
% 
%     methods
%         % Handover 객체 생성
%         function obj = class_Handover(serv_idx)
%             obj.preparation_state = false;
%             obj.execution_state = false;
%             obj.prep_time = 0;
%             obj.exec_time = 0;
%             obj.serv_idx = serv_idx;
%             obj.targ_idx = 0;
%             obj.TTT_check = 0;
%             obj.exec_TTT_check = 0;
%             obj.last_ho_time = 0;
%             obj.last_site_idx = 0;
%             obj.Xp_locked = false; % 초기화
%             obj.Xp_locked_next = false; % 초기화
%             obj.PD_check = 0;  % 전파 지연 타이머 초기화
%             obj.valid_indices = [];  % 필터링된 후보 셀 인덱스 초기화
%         end
% 
%         % Handover 준비 상태 초기화
%         function obj = initiate_preparation(obj, current_time, new_targ_idx)
%             obj.preparation_state = true;
%             obj.prep_time = current_time;
%             obj.targ_idx = new_targ_idx;
%         end
% 
%         % Handover 실행 상태 초기화
%         function obj = initiate_execution(obj, current_time)
%             obj.execution_state = true;
%             obj.exec_time = current_time;
%         end
% 
%         % Handover 객체 초기화
%         function obj = reset(obj, new_serv_idx)
%             obj.preparation_state = false;
%             obj.execution_state = false;
%             obj.prep_time = 0;
%             obj.exec_time = 0;
%             obj.serv_idx = new_serv_idx;
%             obj.targ_idx = 0;
%             obj.TTT_check = 0;
%             obj.exec_TTT_check = 0;
%             obj.PD_check = 0;  % PD 타이머 초기화
%             obj.Xp_locked = false; % 초기화
%             obj.Xp_locked_next = false; % 초기화
%             obj.valid_indices = [];  % 후보 셀 인덱스 초기화
%         end
% 
%         % 전파 지연 타이머 초기화 메서드 추가
%         function obj = PD_reset(obj)
%             obj.PD_check = 0;  % 전파 지연 타이머 초기화
%         end
%     end
% end

classdef class_Handover
    properties
        preparation_state;
        execution_state;
        prep_time;
        exec_time;
        serv_idx;
        targ_idx;
        TTT_check;
        exec_TTT_check;
        prep_cond_fail_count;
        last_ho_time;
        last_site_idx;
        Xp_locked;
        Xp_locked_next;
        PD_check;
        valid_indices;  % 필터링된 후보 셀 인덱스 저장
        msg_phase;
        msg_due_time;
        ho_req_tx_time;
        ho_req_rx_time;
        ho_req_ack_tx_time;
        ho_req_ack_rx_time;
        cho_cmd_tx_time;
        cho_cmd_rx_time;
        cfra_preamble_tx_time;
        cfra_preamble_rx_time;
        cfra_rsp_tx_time;
        cfra_rsp_rx_time;
        ho_complete_tx_time;
        ho_complete_rx_time;
        mit_detach_time;
        used_rach_fallback;
        dynamic_grant_queue;
        dyn_grant_next_tx_time;
        dyn_grant_last_scan_time;
        dyn_grant_deadline;
        control_msg_queue;
        proc_serv_evt;
        proc_targ_evt;
        proc_exec_ue_evt;
        proc_interrupt_evt;
        proc_ue_hc_evt;
        proc_grant_sched_evt;
        proc_fallback_rach_evt;
    end

    methods
        % Handover 객체 생성
        function obj = class_Handover(serv_idx)
            obj.preparation_state = false;
            obj.execution_state = false;
            obj.prep_time = 0;
            obj.exec_time = 0;
            obj.serv_idx = serv_idx;
            obj.targ_idx = 0;
            obj.TTT_check = 0;
            obj.exec_TTT_check = 0;
            obj.prep_cond_fail_count = 0;
            obj.last_ho_time = 0;
            obj.last_site_idx = 0;
            obj.Xp_locked = false;
            obj.Xp_locked_next = false;
            obj.PD_check = 0;
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
            obj.msg_phase = "IDLE";
            obj.msg_due_time = inf;
            obj.ho_req_tx_time = NaN;
            obj.ho_req_rx_time = NaN;
            obj.ho_req_ack_tx_time = NaN;
            obj.ho_req_ack_rx_time = NaN;
            obj.cho_cmd_tx_time = NaN;
            obj.cho_cmd_rx_time = NaN;
            obj.cfra_preamble_tx_time = NaN;
            obj.cfra_preamble_rx_time = NaN;
            obj.cfra_rsp_tx_time = NaN;
            obj.cfra_rsp_rx_time = NaN;
            obj.ho_complete_tx_time = NaN;
            obj.ho_complete_rx_time = NaN;
            obj.mit_detach_time = NaN;
            obj.used_rach_fallback = false;
            obj.dynamic_grant_queue = struct('arrival_time', {}, 'expiry_time', {}, 'tx_time', {});
            obj.dyn_grant_next_tx_time = NaN;
            obj.dyn_grant_last_scan_time = NaN;
            obj.dyn_grant_deadline = NaN;
            obj.control_msg_queue = struct('msg_type', {}, 'tx_time', {}, 'arrival_time', {}, 'expiry_time', {}, 'meta', {});
            obj.proc_serv_evt = NaN;
            obj.proc_targ_evt = NaN;
            obj.proc_exec_ue_evt = NaN;
            obj.proc_interrupt_evt = NaN;
            obj.proc_ue_hc_evt = NaN;
            obj.proc_grant_sched_evt = NaN;
            obj.proc_fallback_rach_evt = NaN;
        end

        % Handover 준비 상태 설정
        function obj = initiate_preparation(obj, current_time, new_targ_idx)
            obj.preparation_state = true;
            obj.prep_time = current_time;
            obj.targ_idx = new_targ_idx;
            obj.prep_cond_fail_count = 0;
        end

        % Handover 실행 상태 설정
        function obj = initiate_execution(obj, current_time)
            obj.execution_state = true;
            obj.exec_time = current_time;
        end

        % Handover 상태 초기화
        function obj = reset(obj, new_serv_idx)
            obj.preparation_state = false;
            obj.execution_state = false;
            obj.prep_time = 0;
            obj.exec_time = 0;
            obj.serv_idx = new_serv_idx;
            obj.targ_idx = 0;
            obj.TTT_check = 0;
            obj.exec_TTT_check = 0;
            obj.prep_cond_fail_count = 0;
            obj.PD_check = 0;
            obj.Xp_locked = false;
            obj.Xp_locked_next = false;
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
            obj.msg_phase = "IDLE";
            obj.msg_due_time = inf;
            obj.ho_req_tx_time = NaN;
            obj.ho_req_rx_time = NaN;
            obj.ho_req_ack_tx_time = NaN;
            obj.ho_req_ack_rx_time = NaN;
            obj.cho_cmd_tx_time = NaN;
            obj.cho_cmd_rx_time = NaN;
            obj.cfra_preamble_tx_time = NaN;
            obj.cfra_preamble_rx_time = NaN;
            obj.cfra_rsp_tx_time = NaN;
            obj.cfra_rsp_rx_time = NaN;
            obj.ho_complete_tx_time = NaN;
            obj.ho_complete_rx_time = NaN;
            obj.mit_detach_time = NaN;
            obj.used_rach_fallback = false;
            obj.dynamic_grant_queue = struct('arrival_time', {}, 'expiry_time', {}, 'tx_time', {});
            obj.dyn_grant_next_tx_time = NaN;
            obj.dyn_grant_last_scan_time = NaN;
            obj.dyn_grant_deadline = NaN;
            obj.control_msg_queue = struct('msg_type', {}, 'tx_time', {}, 'arrival_time', {}, 'expiry_time', {}, 'meta', {});
            obj.proc_serv_evt = NaN;
            obj.proc_targ_evt = NaN;
            obj.proc_exec_ue_evt = NaN;
            obj.proc_interrupt_evt = NaN;
            obj.proc_ue_hc_evt = NaN;
            obj.proc_grant_sched_evt = NaN;
            obj.proc_fallback_rach_evt = NaN;
        end

        function obj = enqueue_control_msg(obj, msgType, txTime, arrivalTime, expiryTime, meta)
            if nargin < 6 || isempty(expiryTime)
                expiryTime = inf;
            end
            if nargin < 7
                meta = struct();
            end
            obj.control_msg_queue(end+1) = struct( ...
                'msg_type', string(msgType), ...
                'tx_time', txTime, ...
                'arrival_time', arrivalTime, ...
                'expiry_time', expiryTime, ...
                'meta', meta);
        end

        function obj = prune_control_queue(obj, currentTime)
            q = obj.control_msg_queue;
            if isempty(q)
                return;
            end
            keep = [q.expiry_time] >= currentTime;
            obj.control_msg_queue = q(keep);
        end

        function [obj, msg, found] = pop_due_control_msg(obj, currentTime, msgType)
            msg = struct('msg_type', "", 'tx_time', NaN, 'arrival_time', NaN, 'expiry_time', NaN, 'meta', struct());
            found = false;
            q = obj.control_msg_queue;
            if isempty(q)
                return;
            end

            due = find([q.arrival_time] <= currentTime & [q.expiry_time] >= currentTime);
            if isempty(due)
                return;
            end

            if nargin >= 3 && ~isempty(msgType)
                mt = string(msgType);
                due = due(arrayfun(@(idx) q(idx).msg_type == mt, due));
                if isempty(due)
                    return;
                end
            end

            [~, local] = min([q(due).arrival_time]);
            pick = due(local);
            msg = q(pick);
            found = true;
            q(pick) = [];
            obj.control_msg_queue = q;
        end

        function obj = clear_control_queue(obj)
            obj.control_msg_queue = struct('msg_type', {}, 'tx_time', {}, 'arrival_time', {}, 'expiry_time', {}, 'meta', {});
        end

        % 후보 셀 인덱스를 업데이트
        function obj = update_valid_indices(obj, valid_idx)
            obj.valid_indices = valid_idx;  % 후보 셀 인덱스 업데이트
        end

        % 후보 셀 인덱스를 리셋
        function obj = reset_valid_indices(obj)
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
        end
    end
end
