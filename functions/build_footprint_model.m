function footprint = build_footprint_model(mode, opts)
%BUILD_FOOTPRINT_MODEL Build footprint struct compatible with compute_time_window.
% Supported modes:
%   'circle'            : use opts.Rs
%   'hex'               : use opts.Rs
%   'ellipse_elevation' : A = R0 / max(sin(elev), epsElev), B = R0
%   'ellipse_fit'       : fit from boundary points (opts.boundary_points)

    if nargin < 2
        opts = struct();
    end
    mode = lower(string(mode));

    if ~isfield(opts, 'maxTe'), opts.maxTe = inf; end

    switch mode
        case "circle"
            if ~isfield(opts, 'Rs'), error('circle mode requires opts.Rs'); end
            footprint = struct('model','circle', 'R', opts.Rs, 'maxTe', opts.maxTe);

        case "hex"
            if ~isfield(opts, 'Rs'), error('hex mode requires opts.Rs'); end
            footprint = struct('model','hex', 'R', opts.Rs, 'maxTe', opts.maxTe);

        case "ellipse_elevation"
            if ~isfield(opts, 'R0'), error('ellipse_elevation requires opts.R0'); end
            if ~isfield(opts, 'elev_rad'), error('ellipse_elevation requires opts.elev_rad'); end
            if ~isfield(opts, 'epsElev'), opts.epsElev = 1e-3; end
            if ~isfield(opts, 'theta') || isempty(opts.theta), opts.theta = 0; end

            A = opts.R0 / max(sin(opts.elev_rad), opts.epsElev);
            B = opts.R0;
            footprint = struct('model','ellipse', 'A',A, 'B',B, 'theta',opts.theta, 'maxTe', opts.maxTe, ...
                               'source','ellipse_elevation');

        case "ellipse_fit"
            if ~isfield(opts, 'boundary_points')
                error('ellipse_fit requires opts.boundary_points');
            end
            fit = fit_ellipse_from_points(opts.boundary_points);
            footprint = struct('model','ellipse', 'A',fit.A, 'B',fit.B, 'theta',fit.theta, ...
                               'center', fit.center, 'Q', fit.Q, 'maxTe', opts.maxTe, ...
                               'source','ellipse_fit', 'fit_method', fit.method);

        otherwise
            error('Unsupported build_footprint_model mode: %s', mode);
    end
end
