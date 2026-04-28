function [Th, Tc, info] = compute_time_window(UE_xy, C_xy, R, v_sat_xy, v_ue_xy, use_hex, verbose, footprint)
%COMPUTE_TIME_WINDOW Residence-time predictor for circle/hex/ellipse footprints.
% Backward compatible signature:
%   [Th, Tc, info] = compute_time_window(UE_xy, C_xy, R, v_sat_xy, v_ue_xy, use_hex, verbose)
% New optional mode selector:
%   footprint.model = 'circle' | 'hex' | 'ellipse'
%   footprint.A, footprint.B, footprint.theta (ellipse)
%   footprint.maxTe (optional clamp for inf timers)

if nargin < 6 || isempty(use_hex), use_hex = true; end
if nargin < 7 || isempty(verbose), verbose = false; end
if nargin < 8 || isempty(footprint)
    footprint = struct();
end
if ~isfield(footprint, 'model') || isempty(footprint.model)
    if use_hex
        footprint.model = 'hex';
    else
        footprint.model = 'circle';
    end
end
if ~isfield(footprint, 'maxTe')
    footprint.maxTe = inf;
end

r0 = (UE_xy(:) - C_xy(:));
v_rel = (v_sat_xy(:) - v_ue_xy(:));

[Tc, infoC] = tos_remain_circle(r0, v_rel, R, verbose);
model = lower(char(string(footprint.model)));

switch model
    case 'circle'
        Th = Tc;
        modelInfo = infoC;
    case 'hex'
        [Th, infoH] = tos_remain_hex(r0, v_rel, R, verbose);
        modelInfo = infoH;
    case 'ellipse'
        if ~isfield(footprint, 'A') || ~isfield(footprint, 'B')
            error('ellipse mode requires footprint.A and footprint.B');
        end
        if ~isfield(footprint, 'theta') || isempty(footprint.theta)
            footprint.theta = 0;
        end
        [Th, infoE] = tos_remain_ellipse(r0, v_rel, footprint.A, footprint.B, footprint.theta, footprint.maxTe, verbose);
        modelInfo = infoE;
    otherwise
        error('Unsupported footprint.model: %s', model);
end

info = struct();
info.model = model;
info.r0 = r0;
info.v_rel = v_rel;
info.Tc = Tc;
info.Th = Th;
info.circle = infoC;
info.active = modelInfo;
if strcmp(model, 'ellipse')
    info.ellipse = modelInfo;
else
    info.ellipse = struct();
end
end

function [Tc, info] = tos_remain_circle(r0, v, R, verbose)
    rx = r0(1); ry = r0(2); vx = v(1); vy = v(2);
    V2 = vx*vx + vy*vy; V = sqrt(V2);
    r2 = rx*rx + ry*ry; R2 = R*R;

    info.model = 'circle';
    info.inside = (r2 < R2 + 1e-9);
    info.status = 'ok';

    if V < 1e-12
        Tc = inf;
        info.status = 'stationary';
        return;
    end

    rv = rx*vx + ry*vy;
    tTCA = -rv / V2;
    dmin2 = r2 - (rv*rv)/V2;
    Dt = sqrt(max(0, R2 - dmin2)) / V;
    Tc = tTCA + Dt;

    if ~info.inside
        Tc = 0;
        info.status = 'outside';
    end

    if verbose
        fprintf('[circle] inside=%d status=%s Tc=%.6f\n', info.inside, info.status, Tc);
    end
end

function [Te, info] = tos_remain_ellipse(r0, v, A, B, theta, maxTe, verbose)
    if nargin < 6 || isempty(maxTe)
        maxTe = inf;
    end

    Q = make_ellipse_Q(A, B, theta);
    a = v' * Q * v;
    b = 2 * (r0' * Q * v);
    c = (r0' * Q * r0) - 1;
    disc = b^2 - 4*a*c;

    roots_tau = [];
    selected = NaN;
    inside = (c <= 1e-12);
    status = 'ok';

    if ~inside
        Te = 0;
        status = 'outside';
    elseif a < 1e-12
        Te = inf;
        status = 'stationary';
    elseif disc < 0
        Te = inf;
        status = 'no_crossing';
    else
        rr = [(-b - sqrt(disc))/(2*a), (-b + sqrt(disc))/(2*a)];
        rr = rr(imag(rr) == 0);
        rr = real(rr(rr > 1e-9));
        roots_tau = rr;
        if isempty(rr)
            Te = inf;
            status = 'no_positive_root';
        else
            selected = min(rr);
            Te = selected;
        end
    end

    if isfinite(maxTe) && Te > maxTe
        Te = maxTe;
        status = 'clamped';
    end

    info = struct('model','ellipse', 'Q',Q, 'a',a, 'b',b, 'c',c, ...
                  'discriminant',disc, 'roots',roots_tau, ...
                  'selected_root',selected, 'inside',inside, 'status',status, ...
                  'A',A, 'B',B, 'theta',theta, 'maxTe',maxTe);

    if verbose
        fprintf('[ellipse] inside=%d status=%s Te=%.6f\n', inside, status, Te);
    end
end

function [Th, info] = tos_remain_hex(r0, v, R, verbose)
    [Hx, Hy] = hex_vertices(0, 0, R);
    in = inpolygon(r0(1), r0(2), Hx, Hy);
    info.model = 'hex';
    info.inside = in;
    info.status = 'ok';

    if ~in
        Th = 0;
        info.status = 'outside';
        return;
    end

    t_candidates = [];
    for i = 1:6
        i2 = i+1; if i2 == 7, i2 = 1; end
        P1 = [Hx(i), Hy(i)];
        P2 = [Hx(i2), Hy(i2)];
        t = ray_segment_intersection_time(r0, v, P1, P2);
        if ~isnan(t) && t > 1e-9
            t_candidates(end+1) = t; %#ok<AGROW>
        end
    end

    if isempty(t_candidates)
        Th = inf;
        info.status = 'no_crossing';
    else
        Th = min(t_candidates);
    end

    if verbose
        fprintf('[hex] inside=%d status=%s Th=%.6f\n', in, info.status, Th);
    end
end

function [Hx, Hy] = hex_vertices(cx, cy, R)
    ang = deg2rad(0:60:300);
    Hx = cx + R*cos(ang);
    Hy = cy + R*sin(ang);
end

function t = ray_segment_intersection_time(r0, v, p1, p2)
    A = [v(:), -(p2(:)-p1(:))];
    b = p1(:) - r0(:);
    if abs(det(A)) < 1e-12
        t = NaN;
        return;
    end
    x = A \ b;
    t = NaN;
    if x(1) >= -1e-12 && x(2) >= -1e-12 && x(2) <= 1+1e-12
        t = max(0, x(1));
    end
end
