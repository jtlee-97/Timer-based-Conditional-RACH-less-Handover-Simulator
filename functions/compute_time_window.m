function [Th, Tc, info] = compute_time_window(UE_xy, C_xy, R, v_sat_xy, v_ue_xy, use_hex, verbose)
% Compute Th (hex) and Tc (circle) remain times from current state.
% - UE_xy: [x y] UE 위치
% - C_xy : [x y] 서빙 셀 중심
% - R    : [m]   셀 반지름 (외접반지름, 원과 헥사곤 동일 값 사용)
% - v_sat_xy: [vx vy] 위성 지상투영 속도
% - v_ue_xy : [vx vy] UE 속도 (모빌리티)
% - use_hex : (bool) hex 경계 고려 (기본 true 권장)
% - verbose : (bool)
%
% Return:
%   Th: 헥사곤 경계까지 남은 시간 (밖이면 0)
%   Tc: 원 경계까지 남은 시간 (밖이면 0)
%   info: 구조체 디버그용

if nargin < 6 || isempty(use_hex), use_hex = true; end
if nargin < 7, verbose = false; end

r0 = UE_xy - C_xy;                  % 상대 위치
v_rel = v_sat_xy - v_ue_xy;         % 상대 속도

[Tc, infoC] = tos_remain_circle(r0, v_rel, R, verbose);
if use_hex
    [Th, infoH] = tos_remain_hex(r0, v_rel, R, verbose);
else
    Th = Tc;                         % 헥사곤 대신 원으로 근사 사용 가능
    infoH = struct('isInside', infoC.isInside);
end

info = struct('r0', r0, 'v_rel', v_rel, ...
              'Tc', Tc, 'Th', Th, ...
              'circle', infoC, 'hex', infoH);
end

% ---- 아래 3개 helper는 질문에 준 코드 그대로 이식 ----
function [Tc, info] = tos_remain_circle(r0, v, R, VERBOSE)
    rx=r0(1); ry=r0(2); vx=v(1); vy=v(2);
    V2 = vx*vx + vy*vy;  V = sqrt(V2);
    r2 = rx*rx + ry*ry;  R2 = R*R;
    info.isInside = (r2 < R2 + 1e-9);
    if VERBOSE
        fprintf('\n-- Circle DEBUG --\n');
        fprintf('|r0|=%.3f, R=%.3f -> inside=%d, |v|=%.3f\n', sqrt(r2), R, info.isInside, V);
    end
    if V < 1e-9
        Tc = inf; if VERBOSE, fprintf('~zero speed -> Tc=inf\n'); end; return;
    end
    rv = rx*vx + ry*vy;
    tTCA  = - rv / V2;
    dmin2 = r2 - (rv*rv)/V2;
    Dt = sqrt(max(0, R2 - dmin2)) / V;
    Tc = tTCA + Dt;
    if VERBOSE
        fprintf('r0·v=%.3f, tTCA=%.6f, d_min=%.3f, Dt=%.6f, Tc(raw)=%.6f\n', rv, tTCA, sqrt(max(dmin2,0)), Dt, Tc);
    end
    if ~info.isInside
        Tc = 0; if VERBOSE, fprintf('Outside now -> Tc=0 (future dwell=%.6f)\n', 2*Dt); end
    end
end

function [Th, info] = tos_remain_hex(r0, v, R, VERBOSE)
    [Hx, Hy] = hex_vertices(0, 0, R);
    in = inpolygon(r0(1), r0(2), Hx, Hy);
    info.isInside = in;
    if VERBOSE
        fprintf('\n-- Hex DEBUG --\n');
        fprintf('r0=[%.1f, %.1f], inside=%d\n', r0(1), r0(2), in);
    end
    if ~in, Th = 0; if VERBOSE, fprintf('Outside -> Th=0\n'); end; return; end
    t_candidates = [];
    for i = 1:6
        i2 = i+1; if i2==7, i2 = 1; end
        P1=[Hx(i),Hy(i)]; P2=[Hx(i2),Hy(i2)];
        t = ray_segment_intersection_time(r0, v, P1, P2);
        if ~isnan(t) && t > 1e-9, t_candidates(end+1)=t; end %#ok<AGROW>
    end
    if isempty(t_candidates)
        Th = 0; if VERBOSE, fprintf('No edge hit -> Th=0 (degenerate)\n'); end
    else
        Th = min(t_candidates);
        if VERBOSE, fprintf('edge hits: min Th=%.6f\n', Th); end
    end
end

function [Hx, Hy] = hex_vertices(cx, cy, R)
    ang = deg2rad(0:60:300);
    Hx = cx + R*cos(ang); Hy = cy + R*sin(ang);
end

function t = ray_segment_intersection_time(r0, v, p1, p2)
    A = [v(:), -(p2(:)-p1(:))]; b = (p1(:) - r0(:));
    if abs(det(A)) < 1e-12, t = NaN; return; end
    x = A \ b; t = NaN;
    if x(1) >= -1e-12 && x(2) >= -1e-12 && x(2) <= 1+1e-12
        t = max(0, x(1));
    end
end
