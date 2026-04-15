%% demo_HO_distance_only.m
% Distance-only, idealized nearest-center switching
% - Switch when a neighbor center becomes closer than the serving center
% - Build global nearest timeline (A -> ... -> ...)
% - Compare A->B->C vs A->C; skip B if B's dwell < threshold
% - Visualize geometry (hex grid) + timeline
%
% Jetty 요청 반영:
%   * 위성 속도 7.56 km/s = 7560 m/s
%   * UE 속도 100 km/h ≈ 27.7778 m/s
%   * PREP/GUARD/신호/반경 조건 무시 (순수 거리 기준)
%
% Note:
%   - 모든 셀 중심이 같은 지상 드리프트(vc)라고 가정 (현 스크립트)
%   - 셀별 드리프트가 다르면 pair-wise 교차식이 2차식으로 바뀜(확장 가능)

clear; clc; close all;

%% ===================== Parameters =====================
% Geometry (hex grid)
cellRadius = 23120;          % [m] (시각화용 원 반경; 로직에는 영향 X)
cellISD    = 40045.0147;     % [m] center-to-center distance
tiers      = 6;              % 넉넉히 생성 후 2-tier(19개)만 사용

% Time / horizon
K_sec       = 20.0;          % [s] look-ahead horizon for timeline

% Motion (constant-velocity on ground)
ue_speed    = 100/3.6;       % [m/s] UE speed (100 km/h)
ue_dir_deg  = 0;             % [deg] UE heading (0 = +x)
sat_speed   = 7560;          % [m/s] satellite ground-track (7.56 km/s)
sat_dir_deg = -90;           % [deg] cell drift direction (e.g., -y)

% Path comparison policy
SKIP_THRESHOLD = 1.0;        % [s] B dwell < 1s 이면 A->B->C 대신 A->C 권고

% UE initial position (테스트용)
UE_x = 17340;                % [m]
UE_y = 80090.0293;           % [m]

% Drawing sampling (for trajectories)
SAMPLE_TIME = 0.2;           % [s]
tvec = 0:SAMPLE_TIME:K_sec;

%% ===================== Build hex grid =====================
if exist('generateHexagonalCells','file')
    [xc, yc] = generateHexagonalCells(cellRadius, tiers);
else
    [xc, yc] = local_generateHexagonalCells(cellRadius, tiers);
end
nCells = numel(xc);

% Serving cell = nearest at t0
d0_all   = hypot(UE_x - xc, UE_y - yc);
[~, id_serv] = min(d0_all);

% 2-tier (19 cells incl. serving) by nearest-distance
idx_nb = local_pick2TierAround(xc, yc, id_serv, cellISD);
idx_nb = unique([id_serv; idx_nb(:)]);
if numel(idx_nb) > 19, idx_nb = idx_nb(1:19); end
N = numel(idx_nb);

%% ===================== Relative state at t0 =====================
UE_pos = [UE_x, UE_y];
vu     = ue_speed * [cosd(ue_dir_deg), sind(ue_dir_deg)];     % [1x2]
vc     = sat_speed * [cosd(sat_dir_deg), sind(sat_dir_deg)];  % [1x2] common to all
C_pos  = [xc(idx_nb), yc(idx_nb)];                            % [N x 2]
r      = UE_pos - C_pos;                                      % [N x 2] relative pos (t0)
vrel   = vu - vc;                                             % [1 x 2] relative vel (common)

% starting row (in idx_nb) for serving
row_A = find(idx_nb==id_serv, 1);

%% ===================== Build global nearest timeline (distance-only) =====================
events = nearest_timeline(r, vrel, row_A, K_sec);
T_tl   = cell2table(events, 'VariableNames', {'cell_id','t_start','t_end','dwell'});
disp('--- Nearest (distance-only) timeline ---');
disp(T_tl);

%% ===================== Route comparison: A->B->C vs A->C =====================
[AB_list, tAB] = first_two_overtakes(r, vrel, row_A);
if isempty(AB_list)
    fprintf('\nNo overtake from serving within horizon %.1fs.\n', K_sec);
    route_msg = 'A only';
else
    row_B = AB_list(1);
    dwell_B = dwell_of_cell(r, vrel, row_B, tAB, K_sec);

    if numel(AB_list) >= 2
        row_C = AB_list(2);
        tAC   = switch_time_pair(r, vrel, row_A, row_C);
        dwell_C_direct = dwell_of_cell_from(r, vrel, row_C, tAC, K_sec);
        fprintf('\n[A->B->...]  B(cell %d): t_AB=%.2fs, dwell_B=%.2fs\n', idx_nb(row_B), tAB, dwell_B);
        fprintf('[A->C]       C(cell %d): t_AC=%.2fs, dwell_C(direct)=%.2fs\n', idx_nb(row_C), tAC, dwell_C_direct);

        if dwell_B < SKIP_THRESHOLD
            fprintf('=> B dwell < %.2fs → Recommend skipping B: A -> C\n', SKIP_THRESHOLD);
            route_msg = sprintf('Skip B: A->C (B dwell=%.2fs)', dwell_B);
        else
            fprintf('=> B dwell ≥ %.2fs → A->B is viable (then onward)\n', SKIP_THRESHOLD);
            route_msg = sprintf('Keep B: A->B->... (B dwell=%.2fs)', dwell_B);
        end
    else
        fprintf('\n[A->B] only  B(cell %d): t_AB=%.2fs, dwell_B=%.2fs\n', idx_nb(row_B), tAB, dwell_B);
        if dwell_B < SKIP_THRESHOLD
            fprintf('=> B dwell < %.2fs → consider staying on A longer, or check next horizon.\n', SKIP_THRESHOLD);
            route_msg = sprintf('B short(%.2fs): stay A / next step', dwell_B);
        else
            route_msg = sprintf('A->B (B dwell=%.2fs)', dwell_B);
        end
    end
end

%% ===================== Visualization =====================
figure('Color','w','Position',[100 100 1300 560]);

% --- (A) Geometry plot ---
subplot(1,2,1); hold on; axis equal; grid on; box on;
title('Geometry at t_0 (distance-only switching)', 'FontWeight','bold');
xlabel('x [m]'); ylabel('y [m]');

% Draw 2-tier neighbor circles (for context only)
for i = 1:N
    local_drawCircle(C_pos(i,1), C_pos(i,2), cellRadius, 120, [0.85 0.85 0.85]);
    text(C_pos(i,1), C_pos(i,2), sprintf('%d', idx_nb(i)), ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontWeight','bold','Color',[0.2 0.2 0.2]);
end

% Serving center & UE
plot(C_pos(row_A,1), C_pos(row_A,2), 'kp', 'MarkerSize',12, 'MarkerFaceColor','y');
plot(UE_pos(1), UE_pos(2), 'ro', 'MarkerFaceColor','r');

% Trajectories for viz
rayUE = [UE_pos(1) + vu(1)*tvec; UE_pos(2) + vu(2)*tvec]';
plot(rayUE(:,1), rayUE(:,2), 'r--', 'DisplayName','UE traj');

rayC  = [C_pos(row_A,1) + vc(1)*tvec; C_pos(row_A,2) + vc(2)*tvec]';
plot(rayC(:,1), rayC(:,2), 'b:', 'DisplayName','cell drift');

legend({'cell (context)','serving','UE(0)','UE traj','cell drift'}, 'Location','bestoutside');

% --- (B) Timeline plot ---
subplot(1,2,2); hold on; grid on; box on;
title(sprintf('Distance-only nearest timeline (policy: skip if dwell<%.1fs)\n%s', SKIP_THRESHOLD, route_msg), ...
    'FontWeight','bold');
xlabel('time [s]'); ylabel('cells (in order)');
xlim([0 K_sec]);

% rows in timeline order
M = height(T_tl);
ytickpos  = 1:M;
yticklbls = cell(M,1);
for i=1:M
    y = i;
    % gross dwell bar for that segment
    plot([T_tl.t_start(i) T_tl.t_end(i)], [y y], '-', 'Color',[0.1 0.6 0.1], 'LineWidth',8);
    % label
    yticklbls{i} = sprintf('%d', T_tl.cell_id(i));
    % segment text
    text((T_tl.t_start(i)+T_tl.t_end(i))/2, y+0.28, sprintf('%.2fs', T_tl.dwell(i)), ...
        'HorizontalAlignment','center', 'Color',[0 0.4 0]);
end
ylim([0.5, M+0.5]); yticks(ytickpos); yticklabels(yticklbls);

% draw vertical lines at segment boundaries
for i=1:M
    xline(T_tl.t_start(i), 'k:');
end
xline(K_sec,'k:');

%% ===================== Local functions =====================
function events = nearest_timeline(r, vrel, row_curr, K)
% Build global nearest (distance-only) timeline from row_curr over horizon K
% r: [N x 2] (UE - cell) at t0
% vrel: [1 x 2] (UE - cell drift), same for all cells here
% row_curr: starting row index (serving at t0)
% Output events: {cell_id, t_start, t_end, dwell} with cell_id = actual ID
    N = size(r,1);
    t_now = 0;
    events = {};
    idx_nb = evalin('base','idx_nb');  % map row -> actual cell ID
    while t_now < K
        t_next = inf; row_next = row_curr;
        % find earliest valid overtake from current
        for j = 1:N
            if j == row_curr, continue; end
            [t_eq, ok] = switch_time_pair(r, vrel, row_curr, j);
            if ok && t_eq > t_now && t_eq < t_next
                t_next = t_eq; row_next = j;
            end
        end
        if isfinite(t_next)
            t_end = min(t_next, K);
        else
            t_end = K;
        end
        dwell = max(0, t_end - t_now);
        events(end+1,:) = {idx_nb(row_curr), t_now, t_end, dwell}; %#ok<AGROW>
        if ~isfinite(t_next) || t_end >= K
            break;
        end
        t_now   = t_next;
        row_curr= row_next;
    end
end

function [list_rows, t_first] = first_two_overtakes(r, vrel, row_A)
% From serving row_A, list first two cells that overtake A (earliest t_eq)
    N = size(r,1);
    ts = inf(N,1);
    for j=1:N
        if j==row_A, continue; end
        [t_eq, ok] = switch_time_pair(r, vrel, row_A, j);
        if ok, ts(j) = t_eq; end
    end
    [sorted_t, order] = sort(ts,'ascend');
    order = order(isfinite(sorted_t));
    list_rows = order(:)';
    if isempty(list_rows), t_first = NaN;
    else, t_first = sorted_t(find(isfinite(sorted_t),1,'first'));
    end
end

function [t_eq, ok] = switch_time_pair(r, vrel, i, j)
% When does j become closer than i (first valid equal-distance time)?
% Solve: ||r_i + vrel t||^2 = ||r_j + vrel t||^2  (linear in t under common vrel)
% t_eq = (||r_j||^2 - ||r_i||^2) / (2 (r_i - r_j)·vrel)
% j becomes closer for t>t_eq if b_ji = 2 (r_j - r_i)·vrel < 0
    ri = r(i,:); rj = r(j,:);
    den = 2 * dot(ri - rj, vrel);
    num = (dot(rj,rj) - dot(ri,ri));
    if abs(den) < 1e-12
        t_eq = inf; ok = false; return; % parallel / no crossing
    end
    t_eq = num / den;
    bji  = 2 * dot(rj - ri, vrel); % slope: j closer than i for t>t_eq if bji<0
    ok   = (t_eq > 0) && (bji < 0);
    if ~ok, t_eq = inf; end
end

function dwell = dwell_of_cell(r, vrel, row_B, t_in_B, K)
% Dwell time of cell row_B after it becomes nearest at t_in_B
    N = size(r,1);
    t_now = t_in_B;
    t_next = inf;
    for j=1:N
        if j==row_B, continue; end
        [t_eq, ok] = switch_time_pair(r, vrel, row_B, j);
        if ok && t_eq > t_now && t_eq < t_next
            t_next = t_eq;
        end
    end
    if ~isfinite(t_next), t_next = K; end
    dwell = max(0, t_next - t_now);
end

function dwell = dwell_of_cell_from(r, vrel, row_C, t_in_C, K)
% Dwell of C if we go directly A->C (ignore intermediate nearer cells)
    N = size(r,1);
    t_now = t_in_C;
    t_next = inf;
    for j=1:N
        if j==row_C, continue; end
        [t_eq, ok] = switch_time_pair(r, vrel, row_C, j);
        if ok && t_eq > t_now && t_eq < t_next
            t_next = t_eq;
        end
    end
    if ~isfinite(t_next), t_next = K; end
    dwell = max(0, t_next - t_now);
end

function idx = local_pick2TierAround(xc, yc, id0, isd)
% Pick ~2-tier neighbors by nearest centers (serving + 18)
    dx = xc - xc(id0);
    dy = yc - yc(id0);
    d  = hypot(dx, dy);
    [~, order] = sort(d, 'ascend');
    take = min(19, numel(order));
    idx = order(1:take); % includes serving
end

function local_drawCircle(cx, cy, R, nseg, color, lw)
    if nargin<5, color=[0.85 0.85 0.85]; end
    if nargin<6, lw=1.2; end
    th = linspace(0, 2*pi, nseg);
    plot(cx + R*cos(th), cy + R*sin(th), '-', 'Color',color, 'LineWidth',lw);
end

function [x, y] = local_generateHexagonalCells(radius, tiers)
% Same layout as your helper; radius here is "visual spacing" seed
    x = 0; y = 0;
    for tier = 1:tiers
        for side = 0:5
            for step = 0:tier-1
                angle = (side * 60 + 30) * pi / 180;
                dx = radius * sqrt(3) * (tier * cos(angle) - step * sin(angle + pi/6));
                dy = radius * sqrt(3) * (tier * sin(angle) + step * cos(angle + pi/6));
                x = [x; dx]; y = [y; dy];
            end
        end
    end
end
