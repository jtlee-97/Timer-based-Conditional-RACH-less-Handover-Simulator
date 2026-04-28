function cfg = revision_config()
%REVISION_CONFIG Configuration for revision experiments.

cfg = struct();

% Reproducibility / scale
cfg.seed = 20260428;
cfg.num_episodes = 500;
cfg.num_candidates = 6;
cfg.output_dir = fullfile('output', 'revision');

% Base geometry / motion
cfg.Rs = 23120;                 % base radius [m]
cfg.sample_dt = 0.01;           % dense sampling dt for T_ref [s]
cfg.max_horizon = 20;           % reference horizon [s]
cfg.vsat_mps = [0, 7560];
cfg.ue_speed_range = [0, 60];   % [m/s]

% Footprint model selection
cfg.footprint_baselines = {'circle','hex','ellipse'};
cfg.ellipse_mode = 'ellipse_elevation';  % ellipse_elevation | ellipse_fit
cfg.ellipse_R0 = cfg.Rs;
cfg.ellipse_elev_rad = deg2rad(35);
cfg.ellipse_theta = deg2rad(20);
cfg.maxTe = 60;                 % clamp for inf residence time

% Timing uncertainty and clock drift
cfg.delta_off_set_ms = [0, 2, 5, 10];
cfg.drift_ms_set = [0, 1, 2, 5, 10];

% Candidate ranking weights
cfg.rank_weights = struct('w_rsrp', 0.45, 'w_stay', 0.35, 'w_time', 0.20);

% A3/RSRP sensitivity logging parameters (not claiming timer solves A3 instability)
cfg.a3_k_l3 = 4;
cfg.a3_ttt_ms = 40;
cfg.a3_hys_db = 1;
end
