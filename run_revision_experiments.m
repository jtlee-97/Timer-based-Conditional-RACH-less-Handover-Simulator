function results = run_revision_experiments(cfg)
%RUN_REVISION_EXPERIMENTS Main revision experiment pipeline.
% Generates required CSV and figure outputs under cfg.output_dir.

if nargin < 1 || isempty(cfg)
    cfg = revision_config();
end

rng(cfg.seed);
if ~exist(cfg.output_dir, 'dir')
    mkdir(cfg.output_dir);
end

% Build footprints
fp_circle = build_footprint_model('circle', struct('Rs', cfg.Rs, 'maxTe', cfg.maxTe));
fp_hex = build_footprint_model('hex', struct('Rs', cfg.Rs, 'maxTe', cfg.maxTe));
fp_ellipse = build_footprint_model(cfg.ellipse_mode, struct('R0', cfg.ellipse_R0, ...
    'elev_rad', cfg.ellipse_elev_rad, 'theta', cfg.ellipse_theta, 'maxTe', cfg.maxTe));

predictors = {'circle','hex','ellipse'};
N = cfg.num_episodes;
T_hat = nan(N, numel(predictors));
T_ref_vec = nan(N,1);
status_ref = strings(N,1);

ho_success = zeros(N, numel(predictors));
wasted_ho = zeros(N, numel(predictors));
rb_per_ho = zeros(N, numel(predictors));
mit_ms = zeros(N, numel(predictors));
dlsinr = zeros(N, numel(predictors));
cand_miss = zeros(N, numel(predictors));

for i = 1:N
    [UE_xy, C_xy, v_ue] = sample_episode(cfg);
    v_sat = cfg.vsat_mps;

    [~, Tc, ~] = compute_time_window(UE_xy, C_xy, cfg.Rs, v_sat, v_ue, false, false, fp_circle);
    T_hat(i,1) = Tc;

    [Th_hex, ~, ~] = compute_time_window(UE_xy, C_xy, cfg.Rs, v_sat, v_ue, true, false, fp_hex);
    T_hat(i,2) = Th_hex;

    [Th_ell, ~, ~] = compute_time_window(UE_xy, C_xy, cfg.Rs, v_sat, v_ue, true, false, fp_ellipse);
    T_hat(i,3) = Th_ell;

    [pos_samples, t_grid] = synthesize_linear_track(UE_xy, v_ue, cfg.max_horizon, cfg.sample_dt);
    ctr_samples = repmat(C_xy + (t_grid * v_sat), 1, 1);
    [T_ref, sref, ~] = compute_reference_exit_time(pos_samples, t_grid, ctr_samples, fp_ellipse);
    T_ref_vec(i) = min(T_ref, cfg.maxTe);
    status_ref(i) = string(sref);

    [ho_success(i,:), wasted_ho(i,:), rb_per_ho(i,:), mit_ms(i,:), dlsinr(i,:), cand_miss(i,:)] = ...
        compute_proxy_ho_metrics(T_hat(i,:), T_ref_vec(i), cfg);
end

% Error CDF and summary
err_ms = abs(T_hat - T_ref_vec) * 1e3;
[cdfTable, sumTable] = build_error_tables(err_ms, predictors);
writetable(cdfTable, fullfile(cfg.output_dir, 'tstay_error_cdf.csv'));
writetable(sumTable, fullfile(cfg.output_dir, 'tstay_error_summary.csv'));

% HO metrics by predictor
hoTable = table(string(predictors(:)), ...
    mean(ho_success,1).', mean(wasted_ho,1).', mean(rb_per_ho,1).', ...
    mean(mit_ms,1).', mean(dlsinr,1).', mean(cand_miss,1).', ...
    'VariableNames', {'predictor','ho_success_rate','wasted_ho_ratio','rb_equiv_per_ho','avg_mit_ms','avg_dl_sinr_db','candidate_miss_ratio'});
writetable(hoTable, fullfile(cfg.output_dir, 'ho_metrics_by_predictor.csv'));

% Clock drift sensitivity (ellipse predictor based)
driftTable = build_clock_drift_table(T_hat(:,3), T_ref_vec, cfg);
writetable(driftTable, fullfile(cfg.output_dir, 'clock_drift_sensitivity.csv'));

% Config log
write_config_log(cfg, fullfile(cfg.output_dir, 'config_used.txt'));

% Figures
fig_error_cdf(err_ms, predictors, cfg.output_dir);
fig_clock_drift(driftTable, cfg.output_dir);
fig_ho_metrics(hoTable, cfg.output_dir);

results = struct('cdf', cdfTable, 'summary', sumTable, 'clock', driftTable, 'ho', hoTable, ...
                 'T_hat', T_hat, 'T_ref', T_ref_vec, 'status_ref', status_ref);
end

function [UE_xy, C_xy, v_ue] = sample_episode(cfg)
    C_xy = [0, 0];
    r = cfg.Rs * sqrt(rand());
    ang = 2*pi*rand();
    UE_xy = [r*cos(ang), r*sin(ang)];
    spd = cfg.ue_speed_range(1) + rand() * diff(cfg.ue_speed_range);
    hdg = 2*pi*rand();
    v_ue = [spd*cos(hdg), spd*sin(hdg)];
end

function [pos_samples, t_grid] = synthesize_linear_track(p0, v, T, dt)
    t_grid = (0:dt:T).';
    pos_samples = p0 + t_grid * v;
end

function [s, w, rb, mit, sinr, miss] = compute_proxy_ho_metrics(T_hat_row, T_ref, cfg)
    K = numel(T_hat_row);
    s = zeros(1,K); w = zeros(1,K); rb = zeros(1,K); mit = zeros(1,K); sinr = zeros(1,K); miss = zeros(1,K);

    for k = 1:K
        e = abs(T_hat_row(k) - T_ref);
        s(k) = max(0, 1 - e / (0.2 + T_ref));
        w(k) = min(1, e / (0.2 + T_ref));
        rb(k) = 1.0 + 0.5*w(k);
        mit(k) = 12 + 20*w(k);
        sinr(k) = 10 - 5*w(k);

        cand = struct();
        cand.rsrp = -95 + 5*randn(1,cfg.num_candidates);
        cand.pred_stay = max(0.01, T_hat_row(k) + 0.2*randn(1,cfg.num_candidates));
        cand.exec_time = T_hat_row(k) + 0.1*randn(1,cfg.num_candidates);
        cand.t_exit_serving = T_hat_row(k);
        cand.prepared_mask = rand(1,cfg.num_candidates) > 0.25;
        [ord, ~, d] = rank_candidates_tscho(cand, cfg.rank_weights);
        if d.candidate_miss
            miss(k) = 1;
            % fallback proxy: degrade success slightly
            s(k) = max(0, s(k) - 0.08);
            rb(k) = rb(k) + 0.1;
        end
        if isempty(ord)
            miss(k) = 1;
        end
    end
end

function [cdfTable, sumTable] = build_error_tables(err_ms, predictors)
    grid = linspace(0, max(err_ms(:))+1e-9, 200).';
    cdfTable = table(grid, 'VariableNames', {'error_ms'});

    rows = numel(predictors);
    mean_v = zeros(rows,1); med_v = zeros(rows,1); p90 = zeros(rows,1);
    p95 = zeros(rows,1); p99 = zeros(rows,1); mx = zeros(rows,1);

    for k = 1:rows
        e = err_ms(:,k);
        cdf_k = arrayfun(@(x) mean(e <= x), grid);
        cdfTable.(predictors{k}) = cdf_k;

        mean_v(k) = mean(e);
        med_v(k) = median(e);
        p90(k) = prctile(e, 90);
        p95(k) = prctile(e, 95);
        p99(k) = prctile(e, 99);
        mx(k) = max(e);
    end

    sumTable = table(string(predictors(:)), mean_v, med_v, p90, p95, p99, mx, ...
        'VariableNames', {'predictor','mean_error_ms','median_error_ms','p90_ms','p95_ms','p99_ms','max_ms'});
end

function driftTable = build_clock_drift_table(T_hat_ellipse, T_ref, cfg)
    dset = cfg.drift_ms_set(:);
    n = numel(dset);
    ho = zeros(n,1); wasted = zeros(n,1); rb = zeros(n,1); mit = zeros(n,1); sinr = zeros(n,1);

    for i = 1:n
        drift = dset(i)/1e3;
        t_used = T_hat_ellipse + drift;
        e = abs(t_used - T_ref);
        ho(i) = mean(max(0, 1 - e ./ (0.2 + T_ref)));
        wasted(i) = mean(min(1, e ./ (0.2 + T_ref)));
        rb(i) = mean(1.0 + 0.5*min(1, e ./ (0.2 + T_ref)));
        mit(i) = mean(12 + 20*min(1, e ./ (0.2 + T_ref)));
        sinr(i) = mean(10 - 5*min(1, e ./ (0.2 + T_ref)));
    end

    driftTable = table(dset, ho, wasted, rb, mit, sinr, ...
        'VariableNames', {'clock_drift_ms','ho_success_rate','wasted_ho_ratio','rb_equiv_per_ho','avg_mit_ms','avg_dl_sinr_db'});
end

function write_config_log(cfg, outFile)
    fid = fopen(outFile, 'w');
    f = fieldnames(cfg);
    for i = 1:numel(f)
        v = cfg.(f{i});
        if isnumeric(v)
            fprintf(fid, '%s: %s\n', f{i}, mat2str(v));
        elseif ischar(v) || isstring(v)
            fprintf(fid, '%s: %s\n', f{i}, char(string(v)));
        elseif iscell(v)
            fprintf(fid, '%s: %s\n', f{i}, strjoin(string(v), ', '));
        else
            fprintf(fid, '%s: [struct]\n', f{i});
        end
    end
    fclose(fid);
end

function fig_error_cdf(err_ms, predictors, outDir)
    h = figure('Visible','off'); hold on; grid on;
    for k = 1:numel(predictors)
        [f, x] = ecdf(err_ms(:,k));
        plot(x, f, 'LineWidth', 1.6);
    end
    xlabel('Absolute residence-time prediction error [ms]');
    ylabel('CDF');
    legend({'Circular','Hexagonal','Elliptical'}, 'Location','southeast');
    title('T_{stay} prediction error CDF');
    saveas(h, fullfile(outDir, 'fig_tstay_error_cdf.png'));
    savefig(h, fullfile(outDir, 'fig_tstay_error_cdf.fig'));
    close(h);
end

function fig_clock_drift(tbl, outDir)
    h = figure('Visible','off');
    yyaxis left;
    plot(tbl.clock_drift_ms, tbl.ho_success_rate, '-o', 'LineWidth', 1.6); hold on;
    plot(tbl.clock_drift_ms, tbl.wasted_ho_ratio, '-s', 'LineWidth', 1.6);
    ylabel('HO success / wasted-HO ratio');
    yyaxis right;
    plot(tbl.clock_drift_ms, tbl.avg_mit_ms, '-^', 'LineWidth', 1.6);
    ylabel('Average MIT [ms]');
    xlabel('Clock drift [ms]');
    title('Clock drift sensitivity');
    grid on;
    legend({'HO success','Wasted-HO','Average MIT'}, 'Location','best');
    saveas(h, fullfile(outDir, 'fig_clock_drift_sensitivity.png'));
    savefig(h, fullfile(outDir, 'fig_clock_drift_sensitivity.fig'));
    close(h);
end

function fig_ho_metrics(tbl, outDir)
    h = figure('Visible','off');
    vals = [tbl.ho_success_rate, tbl.wasted_ho_ratio, tbl.rb_equiv_per_ho, tbl.avg_mit_ms];
    bar(vals);
    set(gca, 'XTickLabel', cellstr(tbl.predictor));
    legend({'HO success','Wasted-HO','RB/HO','MIT(ms)'}, 'Location','bestoutside');
    ylabel('Metric value');
    title('HO/Resource metrics by predictor');
    grid on;
    saveas(h, fullfile(outDir, 'fig_ho_metrics_by_predictor.png'));
    savefig(h, fullfile(outDir, 'fig_ho_metrics_by_predictor.fig'));
    close(h);
end
