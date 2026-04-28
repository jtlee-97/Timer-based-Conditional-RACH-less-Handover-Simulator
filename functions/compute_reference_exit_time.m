function [T_ref, status, detail] = compute_reference_exit_time(pos_samples, t_grid, center, footprint)
%COMPUTE_REFERENCE_EXIT_TIME Dense-sampled reference exit time generator.
% Inputs:
%   pos_samples : Nx2 UE positions over t_grid
%   t_grid      : Nx1 or 1xN monotonically increasing times [s]
%   center      : [1x2] or Nx2 beam center samples
%   footprint   : footprint struct (circle/hex/ellipse)
% Output:
%   T_ref       : first exit time from boundary after t_grid(1)
%   status      : 'ok' | 'outside_at_start' | 'never_exit'
%   detail      : struct with boundary metric trace

    t_grid = t_grid(:);
    N = numel(t_grid);
    if size(pos_samples,1) ~= N
        error('pos_samples rows must match numel(t_grid).');
    end
    if size(pos_samples,2) ~= 2
        error('pos_samples must be Nx2.');
    end

    if size(center,1) == 1
        center = repmat(center, N, 1);
    end
    if size(center,1) ~= N || size(center,2) ~= 2
        error('center must be 1x2 or Nx2.');
    end

    boundary_metric = zeros(N,1);
    inside = false(N,1);
    for i = 1:N
        p = pos_samples(i,:).';
        c = center(i,:).';
        [inside(i), boundary_metric(i)] = is_inside(p, c, footprint);
    end

    if ~inside(1)
        T_ref = 0;
        status = 'outside_at_start';
    else
        idx = find(~inside, 1, 'first');
        if isempty(idx)
            T_ref = inf;
            status = 'never_exit';
        else
            T_ref = t_grid(idx) - t_grid(1);
            status = 'ok';
        end
    end

    detail = struct('boundary_metric', boundary_metric, 'inside_trace', inside);
end

function [inside, metric] = is_inside(p, c, footprint)
    model = lower(string(footprint.model));
    switch model
        case "circle"
            R = footprint.R;
            metric = norm(p-c) / R;
            inside = (metric <= 1 + 1e-12);
        case "hex"
            R = footprint.R;
            [Hx, Hy] = local_hex(c(1), c(2), R);
            inside = inpolygon(p(1), p(2), Hx, Hy);
            metric = double(~inside);
        case "ellipse"
            [dEll, ~] = normalized_ellipse_distance(p, c, footprint.A, footprint.B, footprint.theta);
            metric = dEll;
            inside = (dEll <= 1 + 1e-12);
        otherwise
            error('Unsupported footprint model: %s', model);
    end
end

function [Hx, Hy] = local_hex(cx, cy, R)
    ang = deg2rad(0:60:300);
    Hx = cx + R*cos(ang);
    Hy = cy + R*sin(ang);
end
