%% ================== Config (DEBUG ON) ==================
clear; close all; clc;
VERBOSE = true;     % ★ 로그 많이 보기

R = 23120;          % [m] ≈ 25 km
tiers = 1;
[cellX, cellY] = generateHexagonalCells(R, tiers);

% ----- UE & velocities (현 설정: 셀 밖이라 ToS=0 나옴) -----
UE  = [17340, 0];                      % [m]
v_sat = [0, -7560];                        % [m/s]
v_ue  = [28*cosd(342.3), 28*sind(342.3)];  % [m/s]
v_rel = v_sat - v_ue;

% ----- Serving 선택: 최근접 중심 -----
d2 = (cellX-UE(1)).^2 + (cellY-UE(2)).^2;
[~, idxSrv] = min(d2);
C = [cellX(idxSrv), cellY(idxSrv)];
r0 = UE - C;

% ----- 기본 정보 로그 -----
if VERBOSE
    fprintf('\n==== GEOMETRY DEBUG ====\n');
    fprintf('Serving center C = [%.1f, %.1f] m (idx=%d)\n', C(1), C(2), idxSrv);
    dist = sqrt(sum((UE - C).^2));
    fprintf('UE = [%.1f, %.1f] m,  |UE-C| = %.1f m,  R = %.1f m  => inside(circle)=%d\n', ...
        UE(1), UE(2), dist, R, dist < R);
    fprintf('v_sat = [%.2f, %.2f] m/s,  v_ue = [%.2f, %.2f] m/s,  v_rel = [%.2f, %.2f] (|v_rel|=%.2f)\n', ...
        v_sat(1), v_sat(2), v_ue(1), v_ue(2), v_rel(1), v_rel(2), norm(v_rel));
end

%% ================== Part A: Circle model ==================
[t_out_circle, infoA] = tos_remain_circle(r0, v_rel, R, VERBOSE);

fprintf('[Circle] ToS_remain = %.3f s  (inside=%d)\n', t_out_circle, infoA.isInside);

figure('Color','w'); hold on; axis equal; grid on;
title('ToS\_remain (Circle Footprint)');
th = linspace(0,2*pi,361);
plot(C(1)+R*cos(th), C(2)+R*sin(th), 'k-','LineWidth',1.5);
plot(cellX, cellY, 'k.','MarkerSize',12);
plot(UE(1), UE(2), 'ro','MarkerFaceColor','r');
quiver(UE(1), UE(2), v_rel(1), v_rel(2), 3, 'r','LineWidth',1.2);
if infoA.isInside && isfinite(t_out_circle) && t_out_circle>0
    P_out = UE + v_rel*t_out_circle;
    plot(P_out(1), P_out(2), 'bs','MarkerFaceColor','c');
    legend('Serving circle','Beam centers','UE','v_{rel}','Exit point');
else
    legend('Serving circle','Beam centers','UE','v_{rel}');
end

%% ================== Part B: Hexagon model ==================
[Hx, Hy] = hex_vertices(C(1), C(2), R);
in_hex = inpolygon(UE(1), UE(2), Hx, Hy);
[t_out_hex, infoB] = tos_remain_hex(r0, v_rel, R, VERBOSE);

fprintf('[Hex  ] ToS_remain = %.3f s  (inside=%d)\n', t_out_hex, in_hex);

figure('Color','w'); hold on; axis equal; grid on;
title('ToS\_remain (Hexagon Footprint)');
patch(Hx, Hy, [0.95 0.95 0.95], 'EdgeColor','k');
plot(cellX, cellY, 'k.','MarkerSize',12);
plot(UE(1), UE(2), 'ro','MarkerFaceColor','r');
quiver(UE(1), UE(2), v_rel(1), v_rel(2), 3, 'r','LineWidth',1.2);
if in_hex && isfinite(t_out_hex) && t_out_hex>0
    P_out_hex = UE + v_rel*t_out_hex;
    plot(P_out_hex(1), P_out_hex(2), 'bs','MarkerFaceColor','c');
    legend('Serving hex','Beam centers','UE','v_{rel}','Exit point');
else
    legend('Serving hex','Beam centers','UE','v_{rel}');
end

%% ============== Map to CHO timer (example) =================
alpha = 0.85;
Thresh1_ms_circle = 1e3 * alpha * t_out_circle;
Thresh1_ms_hex    = 1e3 * alpha * t_out_hex;
fprintf('Thresh1 (circle) = %.1f ms,  Thresh1 (hex) = %.1f ms\n', ...
    Thresh1_ms_circle, Thresh1_ms_hex);

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

function [t_out, info] = tos_remain_circle(r0, v, R, VERBOSE)
    rx = r0(1); ry = r0(2); vx = v(1); vy = v(2);
    V2 = vx*vx + vy*vy; V = sqrt(V2);
    r2 = rx*rx + ry*ry; R2 = R*R;
    info.V = V; info.isInside = (r2 < R2 + 1e-9);
    if VERBOSE
        fprintf('\n-- Circle DEBUG --\n');
        fprintf('r0=[%.1f, %.1f], |r0|=%.1f,  R=%.1f -> inside=%d\n', rx, ry, sqrt(r2), R, info.isInside);
        fprintf('v_rel=[%.2f, %.2f], |v_rel|=%.2f\n', vx, vy, V);
    end
    if V < 1e-9, t_out = inf; if VERBOSE, fprintf('V≈0 => t_out=inf\n'); end; return; end

    rv = rx*vx + ry*vy;
    t_TCA = - rv / V2;
    dmin2 = r2 - (rv*rv)/V2;
    Dt = sqrt(max(0, R2 - dmin2)) / V;
    t_out = t_TCA + Dt;

    if VERBOSE
        fprintf('r0·v=%.3f,  t_TCA=%.6f s,  d_min=%.3f m,  Δt=%.6f s,  t_out(raw)=%.6f s\n', ...
            rv, t_TCA, sqrt(max(dmin2,0)), Dt, t_out);
    end
    if ~info.isInside
        t_out = 0;
        if VERBOSE, fprintf('Not inside now -> ToS_remain=0 (future dwell=2Δt=%.6f s)\n', 2*Dt); end
    end
end

function [Hx, Hy] = hex_vertices(cx, cy, R)
    ang = deg2rad(0:60:300);
    Hx = cx + R*cos(ang); Hy = cy + R*sin(ang);
end

function [t_out, info] = tos_remain_hex(r0, v, R, VERBOSE)
    [Hx, Hy] = hex_vertices(0, 0, R);
    in = inpolygon(r0(1), r0(2), Hx, Hy);
    info.isInside = in;
    if VERBOSE
        fprintf('\n-- Hex DEBUG --\n');
        fprintf('r0=[%.1f, %.1f], inside(hex)=%d\n', r0(1), r0(2), in);
    end
    if ~in, t_out = 0; if VERBOSE, fprintf('Outside -> ToS_remain=0\n'); end; return; end

    t_candidates = [];
    for i = 1:6
        i2 = i+1; if i2==7, i2 = 1; end
        P1 = [Hx(i), Hy(i)]; P2 = [Hx(i2), Hy(i2)];
        t = ray_segment_intersection_time(r0, v, P1, P2);
        if ~isnan(t) && t > 1e-9, t_candidates(end+1) = t; end %#ok<AGROW>
    end
    if isempty(t_candidates)
        t_out = 0;
        if VERBOSE, fprintf('No edge hit -> ToS_remain=0 (degenerate case)\n'); end
    else
        t_out = min(t_candidates);
        if VERBOSE, fprintf('edge hits: min t_out = %.6f s\n', t_out); end
    end
end

function t = ray_segment_intersection_time(r0, v, p1, p2)
    A = [v(:), -(p2(:)-p1(:))]; b = (p1(:) - r0(:));
    if abs(det(A)) < 1e-12, t = NaN; return; end
    x = A \ b; t = NaN;
    if x(1) >= -1e-12 && x(2) >= -1e-12 && x(2) <= 1+1e-12
        t = max(0, x(1));
    end
end
