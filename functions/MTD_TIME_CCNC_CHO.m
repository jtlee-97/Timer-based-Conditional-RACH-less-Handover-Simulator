% function ue = MTD_TIME_CCNC_CHO(ue, Offset_A3, TTT, current_time, Th, Tc)
% % 시간 게이트 + A3 일체형 (디버그 로그 포함)
% %  - current_serving_time <  Th : 아무 것도 하지 않음
% %  - Th ≤ t < Tc               : A3 판별/TTT/준비/실행
% %  - t ≥ Tc                    : 이번 체류기간 내 HO 미완이면 RLF 후 복구 (NO HO++)
% 
%     % 방어코드(비정상 입력 방지)
%     if isempty(Th) || ~isfinite(Th) || Th < 0, Th = 0; end
%     if isempty(Tc) || ~isfinite(Tc) || Tc <= 0, Tc = inf; end
% 
%     % 디버그를 위한 엔트리 상태 백업
%     prev_serv = ue.SERV_SITE_IDX;
%     prev_HO   = ue.HO;
% 
%     % === 1) Th 미도달: 대기 ===
%     if ue.current_serving_time < Th
%         % fprintf('[GATE] t=%.3f: waiting Th (t=%.3f < Th=%.3f), serv=%d\n', ...
%         %         current_time, ue.current_serving_time, Th, ue.SERV_SITE_IDX);
%         return;
%     end
% 
%     % === 2) Tc 도달/초과: 시간게이트 RLF ===
%     if ue.current_serving_time >= Tc
%         % 이 시점까지 HO가 완료되지 않았다고 간주 → RLF 1회
%         ue.RLF = ue.RLF + 1;
% 
%         % 진행 중이던 HO 상태 리셋
%         ue.handover = ue.handover.reset(ue.handover.targ_idx);
%         ue.handover.TTT_check = 0;
%         ue.handover.exec_TTT_check = 0;
% 
%         % 즉시 복구: 현재 측정에서 가장 강한 빔으로 재선정
%         [~, best_idx] = max(ue.RSRP_FILTERED);
%         if ~isempty(best_idx) && best_idx > 0 && best_idx ~= ue.SERV_SITE_IDX
%             fprintf('[RLF-GATE] t=%.3f: serv %d -> %d (NO HO++), reason=Tc reached (t=%.3f >= Tc=%.3f)\n', ...
%                     current_time, ue.SERV_SITE_IDX, best_idx, ue.current_serving_time, Tc);
%             ue.SERV_SITE_IDX = best_idx;
%         else
%             fprintf('[RLF-GATE] t=%.3f: keep serv %d (NO HO++), reason=Tc reached (t=%.3f >= Tc=%.3f)\n', ...
%                     current_time, ue.SERV_SITE_IDX, ue.current_serving_time, Tc);
%         end
% 
%         ue.current_serving_start_time = current_time;
%         ue.current_serving_time = 0;
%         return;
%     end
% 
%     % === 3) Th ≤ t < Tc: A3 로직 ===
%     % A3 cond1: 이웃 셀이 (서빙 + 오프셋)보다 커야 함
%     serv = ue.SERV_SITE_IDX;
%     cond1_vec = ue.RSRP_FILTERED > (ue.RSRP_FILTERED(serv) + Offset_A3);
%     cond1_vec(serv) = false;  % 서빙 자신 제외
% 
%     % ---- 상태머신 ----
%     if ~ue.handover.preparation_state && ~ue.handover.execution_state
%         % 준비 전 상태
%         if any(cond1_vec)
%             ue.RBs = ue.RBs + 1;  % MR 오버헤드
% 
%             if ue.handover.TTT_check == 0
%                 ue.handover.TTT_check = current_time;
%                 fprintf('[A3]     t=%.3f: cond1 START (serv=%d, TTT start)\n', current_time, serv);
%             end
% 
%             cand = find(cond1_vec);
%             [~, rel] = max(ue.RSRP_FILTERED(cand));
%             new_targ = cand(rel);
% 
%             if new_targ ~= serv
%                 % TTT 만료 체크
%                 if (current_time - ue.handover.TTT_check) >= TTT
%                     % Tc 경계 보호
%                     if ue.current_serving_time >= Tc
%                         fprintf('[A3]     t=%.3f: TTT met but Tc boundary hit → abort prep (serv=%d, t=%.3f, Tc=%.3f)\n', ...
%                                 current_time, serv, ue.current_serving_time, Tc);
%                         ue.handover.TTT_check = 0;
%                         return;
%                     end
% 
%                     % 준비 시작
%                     ue.handover = ue.handover.initiate_preparation(current_time, new_targ);
%                     ue.RBs = ue.RBs + 2;  % CMD 오버헤드
%                     fprintf('[PREP]   t=%.3f: serv %d -> targ %d (prep start)\n', current_time, serv, new_targ);
% 
%                     % (선택) 열악한 SINR이면 RLF 카운트
%                     if ue.SINR(serv) < -8
%                         ue.RLF = ue.RLF + 1;
%                         fprintf('[RLF?]   t=%.3f: low SINR at serv=%d (SINR=%.2f dB) → RLF++ (no site change here)\n', ...
%                                 current_time, serv, ue.SINR(serv));
%                     end
%                 end
%             end
%         else
%             if ue.handover.TTT_check ~= 0
%                 fprintf('[A3]     t=%.3f: cond1 RESET (serv=%d, TTT reset)\n', current_time, serv);
%             end
%             ue.handover.TTT_check = 0;
%         end
% 
%     elseif ue.handover.preparation_state && ~ue.handover.execution_state
%         % 준비 상태: 타깃에 대해 cond2 확인
%         targ = ue.handover.targ_idx;
%         cond2_t_enter = false;
%         if targ > 0
%             cond2_t_enter = ue.RSRP_FILTERED(targ) > (ue.RSRP_FILTERED(serv) + Offset_A3);
%         end
% 
%         if cond2_t_enter
%             if ue.handover.exec_TTT_check == 0
%                 ue.handover.exec_TTT_check = current_time;
%             end
%             % 실행 지연(추가 TTT)이 없으면 0으로 두고 즉시 실행
%             if (current_time - ue.handover.exec_TTT_check) >= 0
%                 % 실행
%                 ue.handover = ue.handover.initiate_execution(current_time);
% 
%                 % 정상 HO 수행
%                 ue.SERV_SITE_IDX = targ;
%                 ue.current_serving_start_time = current_time;
%                 ue.current_serving_time = 0;
% 
%                 ue.HO  = ue.HO + 1;
%                 ue.RBs = ue.RBs + 6 + 1;  % RA(6) + CF(1)
%                 fprintf('[HO-EXEC] t=%.3f: serv %d -> %d (HO++=%d)\n', ...
%                         current_time, serv, targ, ue.HO);
% 
%                 % 상태 리셋
%                 ue.handover = ue.handover.reset(targ);
%             end
%         else
%             % 실행 조건이 깨졌으면 준비 롤백
%             fprintf('[PREP-X] t=%.3f: cond2 fail → reset prep (serv=%d, targ=%d)\n', ...
%                     current_time, serv, targ);
%             ue.handover.exec_TTT_check = 0;
%             ue.handover = ue.handover.reset(targ);
%         end
%     else
%         % 비정상/경계 보호: 상태 정합이 깨졌으면 리셋
%         fprintf('[STATE-X] t=%.3f: invalid HO state → full reset (serv=%d)\n', current_time, serv);
%         ue.handover = ue.handover.reset(ue.handover.targ_idx);
%         ue.handover.TTT_check = 0;
%         ue.handover.exec_TTT_check = 0;
%     end
% 
%     % (추가 안전로그) 이 함수 내부에서 SERV 변경됐지만 HO++ 안 됐으면 표시
%     if ue.SERV_SITE_IDX ~= prev_serv && ue.HO == prev_HO
%         fprintf('[WARN]   t=%.3f: serv %d -> %d but HO not incremented (check path)\n', ...
%                 current_time, prev_serv, ue.SERV_SITE_IDX);
%     end
% end

function ue = MTD_TIME_CCNC_CHO(ue, Offset_A3, TTT, current_time, Th, Tc)
% 시간 게이트 + A3 일체형 (Tc 도달 시 RLF 금지, 강제 HO로 처리)
%  - t <  Th: 대기
%  - Th ≤ t < Tc: A3/TTT/준비/실행
%  - t ≥  Tc: 강제 HO(가장 강한 빔), NO RLF++

    % 방어
    if isempty(Th) || ~isfinite(Th) || Th < 0, Th = 0; end
    if isempty(Tc) || ~isfinite(Tc) || Tc <= 0, Tc = inf; end

    % 디버그 백업
    prev_serv = ue.SERV_SITE_IDX;
    prev_HO   = ue.HO;

    % 1) Th 미도달
    if ue.current_serving_time < Th
        return;
    end

    % 2) Tc 도달/초과 → 강제 HO (RLF 금지)
    if ue.current_serving_time >= Tc
        [~, best_idx] = max(ue.RSRP_FILTERED);
        ue.handover = ue.handover.reset(ue.handover.targ_idx);
        ue.handover.TTT_check = 0;
        ue.handover.exec_TTT_check = 0;

        if ~isempty(best_idx) && best_idx > 0 && best_idx ~= ue.SERV_SITE_IDX
            % 강제 HO 수행
            ue.SERV_SITE_IDX = best_idx;
            ue.current_serving_start_time = current_time;
            ue.current_serving_time = 0;
            ue.HO  = ue.HO + 1;
            ue.RBs = ue.RBs + 6 + 1;  % RA(6) + CF(1)
            % fprintf('[HO-FORCED-TC] t=%.3f: serv %d -> %d (HO++=%d), reason=Tc (t=%.3f >= Tc=%.3f)\n', ...
            %         current_time, prev_serv, best_idx, ue.HO, ue.current_serving_time, Tc);
        else
            % 바꿀 후보가 없거나 동일 → 유지
            % fprintf('[GATE-TC-NOP]  t=%.3f: keep serv %d, reason=Tc (t=%.3f >= Tc=%.3f)\n', ...
            %         current_time, ue.SERV_SITE_IDX, ue.current_serving_time, Tc);
            ue.current_serving_start_time = current_time;
            ue.current_serving_time = 0;
        end
        return;
    end

    % === Th ≤ t < Tc: A3 로직 ===
    serv = ue.SERV_SITE_IDX;
    cond1_vec = ue.RSRP_FILTERED > (ue.RSRP_FILTERED(serv) + Offset_A3);
    cond1_vec(serv) = false;

    % Tc 임박 보호: 남은 시간이 TTT+여유보다 짧으면 TTT 시작/유지 금지
    time_left  = Tc - ue.current_serving_time;
    guard_time = max(0.05, 0.2*TTT);   % 필요시 조정
    viable_for_ttt = time_left >= (TTT + guard_time);

    if ~ue.handover.preparation_state && ~ue.handover.execution_state
        if any(cond1_vec) && viable_for_ttt
            ue.RBs = ue.RBs + 1;  % MR
            if ue.handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
                % fprintf('[A3]     t=%.3f: cond1 START (serv=%d, TTT start)\n', current_time, serv);
            end

            cand = find(cond1_vec);
            [~, rel] = max(ue.RSRP_FILTERED(cand));
            new_targ = cand(rel);

            if new_targ ~= serv
                if (current_time - ue.handover.TTT_check) >= TTT
                    ue.handover = ue.handover.initiate_preparation(current_time, new_targ);
                    ue.RBs = ue.RBs + 2;  % CMD
                    % fprintf('[PREP]   t=%.3f: serv %d -> targ %d (prep start)\n', current_time, serv, new_targ);
                    % (주의) 여기서 RLF++ 금지. 링크단절은 check_RLF에서만.
                end
            end
        else
            if ue.handover.TTT_check ~= 0
                % fprintf('[A3]     t=%.3f: cond1 RESET/NEAR-Tc (serv=%d, TTT reset)\n', current_time, serv);
            end
            ue.handover.TTT_check = 0;
        end

    elseif ue.handover.preparation_state && ~ue.handover.execution_state
        targ = ue.handover.targ_idx;
        cond2_t_enter = false;
        if targ > 0
            cond2_t_enter = ue.RSRP_FILTERED(targ) > (ue.RSRP_FILTERED(serv) + Offset_A3);
        end

        if cond2_t_enter
            if ue.handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time;
            end
            if (current_time - ue.handover.exec_TTT_check) >= 0
                ue.handover = ue.handover.initiate_execution(current_time);

                ue.SERV_SITE_IDX = targ;
                ue.current_serving_start_time = current_time;
                ue.current_serving_time = 0;

                ue.HO  = ue.HO + 1;
                ue.RBs = ue.RBs + 6 + 1;  % RA + CF
                % fprintf('[HO-EXEC] t=%.3f: serv %d -> %d (HO++=%d)\n', ...
                %         current_time, serv, targ, ue.HO);

                ue.handover = ue.handover.reset(targ);
            end
        else
            % fprintf('[PREP-X] t=%.3f: cond2 fail → reset prep (serv=%d, targ=%d)\n', ...
            %         current_time, serv, targ);
            ue.handover.exec_TTT_check = 0;
            ue.handover = ue.handover.reset(targ);
        end
    else
        % fprintf('[STATE-X] t=%.3f: invalid HO state → full reset (serv=%d)\n', current_time, serv);
        ue.handover = ue.handover.reset(ue.handover.targ_idx);
        ue.handover.TTT_check = 0;
        ue.handover.exec_TTT_check = 0;
    end

    % 안전 로그: SERV 변경됐는데 HO 미증가시 경고
    if ue.SERV_SITE_IDX ~= prev_serv && ue.HO == prev_HO
        % fprintf('[WARN]   t=%.3f: serv %d -> %d but HO not incremented (check path)\n', ...
        %         current_time, prev_serv, ue.SERV_SITE_IDX);
    end
end
