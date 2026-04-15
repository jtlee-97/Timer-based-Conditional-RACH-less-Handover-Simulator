%% ================== Config (DEBUG ON) ==================
clear; close all; clc;
VERBOSE = true;                 % 로그 출력
PLOT    = true;                 % 그림 출력

R = 23120;                      % [m] ≈ 25 km (원/헥사곤 외접반지름 동일)
tiers = 1;
[cellX, cellY] = generateHexagonalCells(R, tiers);

% ----- UE & velocities (예시) -----
UE    = [5983, 17712];              % [m]
v_sat = [0, -7560];                 % [m/s] 위성 지상투영 속도 (예시)
v_ue  = [28*cosd(342.3), 28*sind(342.3)];  % [m/s] UE 속도 (예시)
v_rel = v_sat - v_ue; % 셀과 단말간 상대 속도 정의

% ----- Serving 선택: 최근접 빔 중심 -----
d2 = (cellX-UE(1)).^2 + (cellY-UE(2)).^2;
[~, idxSrv] = min(d2);
C  = [cellX(idxSrv), cellY(idxSrv)];
r0 = UE - C;

if VERBOSE
    fprintf('\n==== GEOMETRY ====\n');
    fprintf('Serving center C=[%.1f, %.1f] (idx=%d)\n', C(1), C(2), idxSrv);
    fprintf('UE=[%.1f, %.1f], |UE-C|=%.1f m, R=%.1f m\n', UE(1), UE(2), norm(r0), R);
    fprintf('v_sat=[%.2f, %.2f], v_ue=[%.2f, %.2f], v_rel=[%.2f, %.2f], |v_rel|=%.2f\n', ...
        v_sat(1), v_sat(2), v_ue(1), v_ue(2), v_rel(1), v_rel(2), norm(v_rel));
end

%% ================== ToS: Circle & Hex ==================
[Tc, infoC] = tos_remain_circle(r0, v_rel, R, VERBOSE);   % 원형
[Th, infoH] = tos_remain_hex(r0, v_rel, R, VERBOSE);      % 헥사곤

fprintf('[ToS] Circle=%.6f s (inside=%d),  Hex=%.6f s (inside=%d)\n', ...
    Tc, infoC.isInside, Th, infoH.isInside);

%% ================== α-설계 및 Thresh1 ==================
alpha_min = 0.80;           % 정책 하한
alpha_max = 0.95;           % 정책 상한
phi       = 0.50;           % 0(보수) ~ 1(여유)

[Thresh1_ms, alpha_eff, B] = choose_thresh_hex_circ(Th, Tc, alpha_min, alpha_max, phi, VERBOSE);
fprintf('[Thresh1] = %.1f ms  (alpha=%.3f), bounds=[%.1f, %.1f] ms\n', ...
    Thresh1_ms, alpha_eff, B.Tmin_ms, B.Tmax_ms);

% %% ================== Plot (optional) =====================
% if PLOT
%     % Circle
%     figure('Color','w'); hold on; axis equal; grid on;
%     title('ToS\_remain (Circle Footprint)');
%     th = linspace(0,2*pi,361);
%     plot(C(1)+R*cos(th), C(2)+R*sin(th), 'k-','LineWidth',1.4);
%     plot(cellX, cellY, 'k.','MarkerSize',12);
%     plot(UE(1), UE(2), 'ro','MarkerFaceColor','r');
%     quiver(UE(1), UE(2), v_rel(1), v_rel(2), 3, 'r','LineWidth',1.2);
%     if infoC.isInside && isfinite(Tc) && Tc>0
%         P_out = UE + v_rel*Tc;
%         plot(P_out(1), P_out(2), 'bs','MarkerFaceColor','c');
%         legend('Serving circle','Beam centers','UE','v_{rel}','Exit point');
%     else
%         legend('Serving circle','Beam centers','UE','v_{rel}');
%     end
% 
%     % Hex
%     figure('Color','w'); hold on; axis equal; grid on;
%     title('ToS\_remain (Hexagon Footprint)');
%     [Hx, Hy] = hex_vertices(C(1), C(2), R);
%     patch(Hx, Hy, [0.95 0.95 0.95], 'EdgeColor','k');
%     plot(cellX, cellY, 'k.','MarkerSize',12);
%     plot(UE(1), UE(2), 'ro','MarkerFaceColor','r');
%     quiver(UE(1), UE(2), v_rel(1), v_rel(2), 3, 'r','LineWidth',1.2);
%     if infoH.isInside && isfinite(Th) && Th>0
%         P_outH = UE + v_rel*Th;
%         plot(P_outH(1), P_outH(2), 'bs','MarkerFaceColor','c');
%         legend('Serving hex','Beam centers','UE','v_{rel}','Exit point');
%     else
%         legend('Serving hex','Beam centers','UE','v_{rel}');
%     end
% end

%% ================== Plot (single figure with both + 6 neighbors) =====================
if PLOT
    % 준비
    [Hx, Hy] = hex_vertices(C(1), C(2), R);
    th = linspace(0,2*pi,361);
    circX = C(1) + R*cos(th);
    circY = C(2) + R*sin(th);

    % 한 화면에 모두
    figure('Color','w'); hold on; axis equal; grid on;
    title('ToS\_remain: Circle vs Hexagon (single view)');

    % 1) Serving hex (patch) & circle (outline)
    hHex    = patch(Hx, Hy, [0.94 0.94 0.94], 'EdgeColor','k', 'LineWidth',1.2);
    hCircle = plot(circX, circY, 'k--', 'LineWidth',1.4);

    % 2) Neighbor 6 circles (가장 가까운 6개)
    dC2 = (cellX-C(1)).^2 + (cellY-C(2)).^2;
    [~, ord] = sort(dC2);                 % 첫 번째는 serving self
    nbrIdx = ord(2:min(7, numel(ord)));   % 최대 6개
    hNbr = []; firstNbr = true;
    for k = 1:numel(nbrIdx)
        Ci = [cellX(nbrIdx(k)), cellY(nbrIdx(k))];
        h = plot(Ci(1)+R*cos(th), Ci(2)+R*sin(th), ...
                 'Color',[0.6 0.6 0.6], 'LineStyle',':', 'LineWidth',1.0);
        if firstNbr, hNbr = h; firstNbr = false; end % legend용 핸들 하나만
    end

    % 3) Beam centers, UE, relative velocity
    hCenters = plot(cellX, cellY, 'k.', 'MarkerSize',12);
    hUE      = plot(UE(1), UE(2), 'ro', 'MarkerFaceColor','r');

    % 상대속도 경로선 (UE -> 앞으로 max(ToS)만큼)
    tmax = max([0, Tc, Th]);
    if tmax > 0
        P_path = UE + v_rel * (1.1*tmax);  % 10% 여유
        hPath = plot([UE(1) P_path(1)], [UE(2) P_path(2)], 'r:', 'LineWidth',1.1);
    else
        hPath = plot(nan, nan); % 자리맞춤
    end
    hVrel = quiver(UE(1), UE(2), v_rel(1), v_rel(2), 3, 'r', 'LineWidth',1.2);

    % 4) Exit points (조건부)
    lgdH = [hHex, hCircle, hNbr, hCenters, hUE, hPath, hVrel];
    lgdL = {'Serving hex','Serving circle','Neighbor circles (6)','Beam centers','UE','v_{rel} path','v_{rel} vector'};

    if infoC.isInside && isfinite(Tc) && Tc>0
        P_outC = UE + v_rel*Tc;
        hExitC = plot(P_outC(1), P_outC(2), 's', 'MarkerEdgeColor','b', ...
                      'MarkerFaceColor','c', 'MarkerSize',8);
        lgdH(end+1) = hExitC;
        lgdL{end+1} = sprintf('Circle exit (T_c=%.3fs)', Tc);
    end

    if infoH.isInside && isfinite(Th) && Th>0
        P_outH = UE + v_rel*Th;
        hExitH = plot(P_outH(1), P_outH(2), 'd', 'MarkerEdgeColor',[0.6 0 0.6], ...
                      'MarkerFaceColor',[0.9 0 0.9], 'MarkerSize',8);
        lgdH(end+1) = hExitH;
        lgdL{end+1} = sprintf('Hex exit (T_h=%.3fs)', Th);
    end

    legend(lgdH, lgdL, 'Location','bestoutside');
    xlabel('x [m]'); ylabel('y [m]');
end


%% ================== Extra Figure: Map + Velocity Subplots =====================
plot_map_and_velocity_subplots(cellX, cellY, R, C, UE, v_sat, v_ue);

function plot_map_and_velocity_subplots(cellX, cellY, R, C, UE, v_sat, v_ue)
    % Left: 모든 셀 원 + 초기 위치/방향(위성/단말/상대)
    % Right: 속도 벡터 삼각형 (v_rel = v_sat - v_ue)

    th = linspace(0,2*pi,361);
    v_rel = v_sat - v_ue;

    % 1x2 서브플롯
    figure('Color','w');
    tlo = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

    %% ---- (Left) Map: cells + initial directions ----
    ax1 = nexttile(tlo,1); hold(ax1,'on'); axis(ax1,'equal'); grid(ax1,'on');
    title(ax1,'Map: All circles + initial positions/directions');
    xlabel(ax1,'x [m]'); ylabel(ax1,'y [m]');

    % (a) 모든 셀 원 (회색 점선)
    for k = 1:numel(cellX)
        cx = cellX(k); cy = cellY(k);
        plot(ax1, cx + R*cos(th), cy + R*sin(th), ...
            'Color',[0.80 0.80 0.80], 'LineStyle',':', 'LineWidth',1.0);
    end

    % (b) 서빙 서클(검정 점선)
    plot(ax1, C(1)+R*cos(th), C(2)+R*sin(th), 'k--', 'LineWidth',1.6);

    % (c) 빔 센터들 + 서빙센터 + UE 위치
    hCenters = plot(ax1, cellX, cellY, 'k.', 'MarkerSize',12);
    hC  = plot(ax1, C(1), C(2), 'ks', 'MarkerFaceColor','w', 'MarkerSize',7);
    hUE = plot(ax1, UE(1), UE(2), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7);

    % (d) 방향 화살표: 보기가 쉬우려면 동일 길이로 정규화
    Ldir = 0.6*R;
    v_sat_dir = Ldir * (v_sat / (norm(v_sat)+eps));
    v_ue_dir  = Ldir * (v_ue  / (norm(v_ue)+eps));
    v_rel_dir = Ldir * (v_rel / (norm(v_rel)+eps));

    hSatDir = quiver(ax1, C(1),  C(2),  v_sat_dir(1), v_sat_dir(2), 0, ...
        'Color',[0.00 0.45 0.74],'LineWidth',1.8,'MaxHeadSize',0.8); % 위성 방향(서빙센터 기준)
    hUEDir  = quiver(ax1, UE(1), UE(2),  v_ue_dir(1),  v_ue_dir(2),  0, ...
        'Color',[0.85 0.33 0.10],'LineWidth',1.8,'MaxHeadSize',0.8); % 단말 방향(UE 기준)
    hRelDir = quiver(ax1, UE(1), UE(2),  v_rel_dir(1), v_rel_dir(2), 0, ...
        'Color',[0.47 0.67 0.19],'LineWidth',1.8,'MaxHeadSize',0.8); % 상대 방향(UE 기준)

    legend(ax1, [hCenters, hC, hUE, hSatDir, hUEDir, hRelDir], ...
        {'Beam centers','Serving center C','UE', ...
         'v_{sat} dir @ C','v_{UE} dir @ UE','v_{rel} dir @ UE'}, ...
        'Location','bestoutside');

    %% ---- (Right) Velocity triangle: v_UE, v_sat, v_rel ----
    ax2 = nexttile(tlo,2);
    plot_velocity_triangle_on_axes(ax2, v_sat, v_ue);

    

end

%% ===== Sanity: how much does UE speed matter here? =====
V_sat = norm(v_sat); V_ue = norm(v_ue); V_rel = norm(v_rel);
e_sat = v_sat / (V_sat + eps);
u_par   = dot(v_ue, e_sat);                 % UE 속도의 위성방향 성분(+면 같은 방향)
u_perp  = norm(v_ue - u_par*e_sat);         % 수직 성분
ang_off = atan2d(u_perp, max(V_sat - u_par, eps));

[Tc_satOnly, ~] = tos_remain_circle(r0, v_sat, R, false);
[Th_satOnly, ~] = tos_remain_hex(r0, v_sat, R, false);

fprintf('\n-- Speed/Direction Decomposition --\n');
fprintf('|v_sat|=%.1f m/s, |v_ue|=%.1f m/s (%.2f%% of |v_sat|)\n', V_sat, V_ue, 100*V_ue/V_sat);
fprintf('UE speed w.r.t sat-dir: parallel=%.2f m/s, perpendicular=%.2f m/s\n', u_par, u_perp);
fprintf('|v_rel|=%.2f m/s (Δ=%.2f m/s, %.3f%%), angle offset≈%.3f°\n', ...
        V_rel, V_rel - V_sat, 100*(V_rel/V_sat - 1), ang_off);

fprintf('\n-- ToS delta due to UE motion --\n');
fprintf('Circle: with UE=%.6fs, sat-only=%.6fs, Δ=%.3f ms (%.2f%%)\n', ...
        Tc, Tc_satOnly, 1e3*(Tc - Tc_satOnly), 100*(Tc/Tc_satOnly - 1));
fprintf('Hex   : with UE=%.6fs, sat-only=%.6fs, Δ=%.3f ms (%.2f%%)\n\n', ...
        Th, Th_satOnly, 1e3*(Th - Th_satOnly), 100*(Th/Th_satOnly - 1));


function plot_velocity_triangle_on_axes(ax, v_sat, v_ue)
    % v_rel = v_sat - v_ue 를 벡터 삼각형으로 표현 (원점 기준)
    v_rel = v_sat - v_ue;

    mag_ue  = norm(v_ue);   mag_sat = norm(v_sat);   mag_rel = norm(v_rel);
    ang_ue  = atan2d(v_ue(2),  v_ue(1));
    ang_sat = atan2d(v_sat(2), v_sat(1));
    ang_rel = atan2d(v_rel(2), v_rel(1));
    dang    = mod(ang_sat - ang_ue + 180, 360) - 180;  % [-180,180)

    M = max([mag_ue, mag_sat, mag_rel, 1]);
    L = 1.15 * M;

    axes(ax); cla(ax); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on');
    title(ax,'Velocity triangle (v_{rel}=v_{sat}-v_{UE})');
    xlabel(ax,'v_x [m/s]'); ylabel(ax,'v_y [m/s]');
    xlim(ax,[-L, L]); ylim(ax,[-L, L]);

    plot(ax, 0,0,'k.','MarkerSize',10);

    hUE  = quiver(ax, 0,0, v_ue(1),  v_ue(2),  0, 'Color',[0.85 0.33 0.10], 'LineWidth',2);
    hSAT = quiver(ax, 0,0, v_sat(1), v_sat(2), 0, 'Color',[0.00 0.45 0.74], 'LineWidth',2);
    hREL = quiver(ax, 0,0, v_rel(1), v_rel(2), 0, 'Color',[0.47 0.67 0.19], 'LineWidth',2);

    % closure: v_UE 끝점에서 v_REL을 그리면 정확히 v_SAT
    hClosure = quiver(ax, v_ue(1), v_ue(2), v_rel(1), v_rel(2), 0, ...
        'LineStyle','--', 'Color',[0.47 0.00 0.70], 'LineWidth',1.6);

    off = 0.02*L;
    text(ax, v_ue(1)+off,  v_ue(2)+off,  sprintf('v_{UE} (|v|=%.1f, %.1f^\\circ)',  mag_ue,  ang_ue),  'Color',[0.85 0.33 0.10]);
    text(ax, v_sat(1)+off, v_sat(2)+off, sprintf('v_{sat} (|v|=%.1f, %.1f^\\circ)', mag_sat, ang_sat), 'Color',[0.00 0.45 0.74]);
    text(ax, v_rel(1)+off, v_rel(2)+off, sprintf('v_{rel} (|v|=%.1f, %.1f^\\circ)', mag_rel, ang_rel), 'Color',[0.47 0.67 0.19]);

    text(ax, -L+0.05*L, L-0.08*L, sprintf('\\angle(v_{UE}, v_{sat}) = %.1f^\\circ', dang), 'Color',[0.2 0.2 0.2]);

    legend(ax, [hUE, hSAT, hREL, hClosure], ...
        {'v_{UE}','v_{sat}','v_{rel} = v_{sat} - v_{UE}','closure: v_{UE}+v_{rel}=v_{sat}'}, ...
        'Location','bestoutside');
end




%% ================= Helper Functions ========================
function [x, y] = generateHexagonalCells(radius, tiers)
    x = 0; y = 0;
    for tier = 1:tiers
        for side = 0:5
            for step = 0:tier-1
                ang = deg2rad(side*60 + 30);
                dx = radius*sqrt(3) * (tier*cos(ang) - step*sin(ang + pi/6));
                dy = radius*sqrt(3) * (tier*sin(ang) + step*cos(ang + pi/6));
                x = [x; dx]; y = [y; dy];
            end
        end
    end
end

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

function [Thresh1_ms, alpha_eff, bounds] = choose_thresh_hex_circ(TH, TC, alpha_min, alpha_max, phi, VERBOSE)
    % 보정: 순서 보장
    if TH > TC, tmp=TH; TH=TC; TC=tmp; end
    eps0 = 1e-9;
    if TC < eps0
        alpha_eff = 0; Thresh1_ms = 0;
        bounds = struct('alpha_L',0,'alpha_U',0,'Tmin_ms',0,'Tmax_ms',0);
        if VERBOSE, fprintf('\n-- Alpha: TC≈0 -> Thresh1=0\n'); end
        return;
    end
    alpha_L = alpha_min * (TH / max(TC,eps0));
    alpha_U = alpha_max;
    alpha_eff = alpha_L + max(0,min(1,phi))*(alpha_U - alpha_L);
    Thresh1_ms = 1e3 * (alpha_eff * TC);
    bounds = struct('alpha_L',alpha_L,'alpha_U',alpha_U, ...
                    'Tmin_ms',1e3*(alpha_min*TH), 'Tmax_ms',1e3*(alpha_max*TC));
    if VERBOSE
        fprintf('\n-- Alpha/Thresh DEBUG --\n');
        fprintf('TH=%.6f s, TC=%.6f s, alpha_L=%.3f, alpha_U=%.3f, alpha(phi)=%.3f\n', TH, TC, alpha_L, alpha_U, alpha_eff);
        fprintf('Bounds: [%.1f, %.1f] ms\n', bounds.Tmin_ms, bounds.Tmax_ms);
    end
end
