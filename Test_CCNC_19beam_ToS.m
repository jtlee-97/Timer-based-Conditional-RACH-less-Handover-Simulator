%% demo_tos_2tier.m
% Distance-only ToS / dwell-time over 2-tier neighbors (19 cells total)
% - Hex grid cells from generateHexagonalCells(cellRadius, tiers)
% - Relative linear motion: UE (v_u) and all cell centers (v_c) move on ground
% - Circular footprint with radius = cellRadius (원형 근사)
% - Computes entry/exit times and ToS analytically for each neighbor

clear; clc; close all;

%% -------------------- Scenario / Parameters --------------------
% Geometry (Set1-600km style)
cellRadius = 23120;          % [m] effective cell ground radius
cellISD    = 40045.0147;     % [m] inter-site distance (center-to-center)
tiers      = 6;              % generate many cells; we'll pick 2-tier around serving

% Time
SAMPLE_TIME = 0.2;           % [s] (e.g., 200 ms)
SAT_SPEED   = 7560;          % [m/s] satellite ground-track speed
K_sec       = 20.0;          % [s] look-ahead horizon for ToS
tvec        = 0:SAMPLE_TIME:K_sec;

% Motion (edit here)
ue_speed    = 15.0;          % [m/s] UE speed (e.g., car)
ue_dir_deg  = 0;             % [deg] UE heading (0 = +x)
sat_dir_deg = -90;           % [deg] cell-centers drift direction (e.g., -y)

% Dwell filter / scheduling helpers
Tmin_dwell  = 1.5;           % [s] minimum dwell to keep (ping-pong guard)

%% -------------------- Build hex grid --------------------
[xc, yc] = generateHexagonalCells(cellRadius, tiers);  %#ok<*NASGU>
nCells   = numel(xc);

% Pick a UE initial position (you can plug your own):
UE_x = 17340;       % e.g., ~mid/edge test (meters)
UE_y = 80090.0293;

% Serving cell = nearest center (at t=0)
d0_all   = hypot(UE_x - xc, UE_y - yc);
[~, id_serv] = min(d0_all);

% 2-tier neighborhood (19 cells total incl. serving):
idx_nb = pick2TierAround(xc, yc, id_serv, cellISD);
% Ensure serving is included and keep up to 19
idx_nb = unique([id_serv; idx_nb(:)]);
if numel(idx_nb) > 19, idx_nb = idx_nb(1:19); end

%% -------------------- Relative motion vectors --------------------
% UE and Cell-center ground-plane velocities
vu = ue_speed * [cosd(ue_dir_deg), sind(ue_dir_deg)];
vc = SAT_SPEED * [cosd(sat_dir_deg), sind(sat_dir_deg)];  % same for all cells here

% For each neighbor cell, build r0 and v_rel
r0 = [UE_x - xc(idx_nb), UE_y - yc(idx_nb)];    % [N x 2]
vrel = vu - vc;                                  % [1 x 2], broadcast to all

%% -------------------- Analytic ToS over circular footprint --------------------
N = numel(idx_nb);
Tin  = nan(N,1);
Tout = nan(N,1);
ToS  = zeros(N,1);
enteredNow = false(N,1);

for i = 1:N
    [tin, tout, tos, entered] = entryExitCircle(r0(i,:), vrel, cellRadius, K_sec);
    Tin(i)        = tin;
    Tout(i)       = tout;
    ToS(i)        = tos;
    enteredNow(i) = entered;
end

% Apply minimum dwell filter (except serving if UE is already inside)
keep = (ToS >= Tmin_dwell) | (idx_nb==id_serv & enteredNow);
Tin  = Tin(keep); Tout = Tout(keep); ToS = ToS(keep); idx_nb = idx_nb(keep);

% Serving cell exit time (for reference)
servMask      = (idx_nb == id_serv);
tExitServing  = Tout(servMask);
if isempty(tExitServing), tExitServing = NaN; end

%% -------------------- Build result table --------------------
T = table(idx_nb(:), Tin(:), Tout(:), ToS(:), enteredNow(keep), ...
    'VariableNames', {'cell_id','t_in_s','t_out_s','ToS_s','insideNow'});
% Sort by (already inside first), then by longer ToS
[~,ord] = sortrows([~T.insideNow, -T.ToS_s, T.t_in_s], [1,2,3]);
T = T(ord,:);

disp('=== 2-tier (19) cells: analytic entry/exit/ToS (distance-only) ===');
disp(T);

fprintf('\nServing cell id = %d | exit time (s) ~ %g\n', id_serv, tExitServing);

%% -------------------- Quick plot (UE ray + circles of 2-tier) --------------------
figure; hold on; axis equal; grid on;
title('Distance-only ToS over 2-tier neighbors');
xlabel('x [m]'); ylabel('y [m]');

% Draw neighbor circles at t=0
for i = 1:numel(idx_nb)
    drawCircle(xc(idx_nb(i)), yc(idx_nb(i)), cellRadius, 120);
end
% Serving center highlight
plot(xc(id_serv), yc(id_serv), 'kp', 'MarkerSize',12, 'MarkerFaceColor','y');

% UE initial and trajectory ray (relative to static frame)
plot(UE_x, UE_y, 'ro', 'MarkerFaceColor','r', 'DisplayName','UE(0)');
ray = [UE_x + vu(1)*tvec; UE_y + vu(2)*tvec]';
plot(ray(:,1), ray(:,2), 'r--', 'DisplayName','UE traj (no cell drift)');

% Also show one cell-center trajectory (serving) along vc for reference
cRay = [xc(id_serv) + vc(1)*tvec; yc(id_serv) + vc(2)*tvec]';
plot(cRay(:,1), cRay(:,2), 'b:', 'DisplayName','Cell-center drift');

legend('Location','bestoutside');

%% -------------------- Helper: print simple schedule hint --------------------
% Earliest feasible next handover target (excluding serving), by soonest t_in
maskNext = T.cell_id ~= id_serv & isfinite(T.t_in_s);
if any(maskNext)
    [~,i2] = min(T.t_in_s(maskNext));
    row    = T(find(maskNext,1,'first') -1 + i2, :); % careful indexing
    fprintf('\nNext candidate by earliest entry: cell %d (t_in=%.2fs, ToS=%.2fs)\n', ...
        row.cell_id, row.t_in_s, row.ToS_s);
    if ~isnan(tExitServing)
        % A simple "window" using serving exit vs target stay
        win_start = max(0, row.t_in_s);         % (여기서는 준비시간/가드 미반영)
        win_end   = min(tExitServing, row.t_out_s);
        fprintf('Rough window: [%.2f, %.2f] s (length %.2fs)\n', ...
            win_start, win_end, max(0,win_end - win_start));
    end
end


%% ==== (A) plot에 cell id 라벨 찍기 ====
for i = 1:numel(idx_nb)
    text(xc(idx_nb(i)), yc(idx_nb(i)), sprintf('%d', idx_nb(i)), ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'Color',[0 0 0], 'FontWeight','bold');
end

%% ==== (B) PREP/GUARD 반영 창 계산 & Top-3 출력 ====
PREP  = 1.0;     % 준비시간 [s]
GUARD = 0.03;    % 소량 가드 [s]

T.win_s = nan(height(T),1);
T.win_e = nan(height(T),1);
T.win_len = nan(height(T),1);

% 서빙 이탈
tExit = tExitServing;
for i = 1:height(T)
    cid = T.cell_id(i);
    if cid == id_serv, continue; end
    % 유효 창: (진입 + PREP + GUARD) ~ min(서빙이탈, 그 셀 이탈)
    win_s = T.t_in_s(i)  + PREP + GUARD;
    win_e = min(tExit, T.t_out_s(i));
    if win_e > win_s
        T.win_s(i) = win_s;
        T.win_e(i) = win_e;
        T.win_len(i) = win_e - win_s;
    end
end

% 후보만 추려서 Top-3 by win_len
cand = T(T.cell_id ~= id_serv & ~isnan(T.win_len), :);
cand = sortrows(cand, {'win_len','t_in_s'}, {'descend','ascend'});

disp('=== Candidates with PREP/GUARD-adjusted windows (Top-3) ===');
disp(cand(1:min(3,height(cand)), {'cell_id','t_in_s','t_out_s','ToS_s','win_s','win_e','win_len'}));


%% ==================== Local functions ====================

function [tin, tout, tos, insideNow] = entryExitCircle(r0, vrel, R, K)
% Analytic entry/exit for circle: ||r0 + vrel t|| <= R
% Returns:
%   tin, tout : first entry and exit times (>=0) clipped to [0,K] if exist
%   tos       : dwell time within [0,K]
%   insideNow : true if t=0 is already inside

    A = dot(vrel, vrel);
    B = dot(r0, vrel);
    C = dot(r0, r0) - R^2;

    insideNow = (C <= 0);
    tin  = NaN; tout = NaN; tos = 0;

    if A < 1e-12
        % relative static: always inside or always outside
        if C <= 0
            tin = 0; tout = K; tos = K; insideNow = true;
        else
            tin = NaN; tout = NaN; tos = 0;  insideNow = false;
        end
        return;
    end

    disc = B^2 - A*C;
    if disc < 0
        % no crossing
        tin = NaN; tout = NaN; tos = 0;  return;
    end

    sdisc = sqrt(max(0,disc));
    t1 = (-B - sdisc)/A;
    t2 = (-B + sdisc)/A;
    if t2 < 0
        % crossings are entirely in the past
        tin = NaN; tout = NaN; tos = 0; return;
    end

    if t1 < 0 && t2 >= 0
        % already inside now
        tin = 0;
        tout = t2;
    else
        % future entry
        tin  = t1;
        tout = t2;
    end

    % Clip to [0,K]
    a = max(0, tin); b = min(K, tout);
    tos = max(0, b - a);
    if tos == 0
        tin = NaN; tout = NaN;
    else
        tin = a; tout = b;
    end
end

function idx = pick2TierAround(xc, yc, id0, isd)
% Rough 2-tier by nearest-center distance:
% 6 (tier-1) + 12 (tier-2) = 18 neighbors around serving
    dx = xc - xc(id0);
    dy = yc - yc(id0);
    d  = hypot(dx, dy);
    [~, order] = sort(d, 'ascend');
    % order(1) == id0; take next 18 as 2 tiers
    take = min(19, numel(order));   % safety
    idx = order(2:take);            % excludes id0
end

function drawCircle(cx, cy, R, nseg)
    th = linspace(0, 2*pi, nseg);
    plot(cx + R*cos(th), cy + R*sin(th), 'k-'); hold on;
end

% If you don't have these in path, uncomment simple hex generator:

function [x, y] = generateHexagonalCells(radius, tiers)
    x = 0; y = 0;
    for tier = 1:tiers
        for side = 0:5
            for step = 0:tier-1
                angle = (side * 60 + 30) * pi/180;
                dx = radius * sqrt(3) * (tier * cos(angle) - step * sin(angle + pi/6));
                dy = radius * sqrt(3) * (tier * sin(angle) + step * cos(angle + pi/6));
                x = [x; dx]; y = [y; dy];
            end
        end
    end
end
