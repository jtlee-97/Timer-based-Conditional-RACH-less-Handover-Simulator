function results = run_geometry_debug()
%RUN_GEOMETRY_DEBUG Equation-validation only (NOT paper/system metrics).

warning('Proxy/debug metrics are for equation validation only and must not be used as paper results.');
addpath(genpath('functions'));
rng(20260428);

outDir = fullfile('output','geometry_debug');
if ~exist(outDir,'dir'), mkdir(outDir); end

N = 500;
R0 = 23120;
elev = deg2rad(35);
A = R0 / max(sin(elev), 1e-3);
B = R0;
theta = deg2rad(20);

errs = zeros(N,3);
debug = zeros(N,11);
status = strings(N,1);

for i=1:N
    r = 0.8*R0*sqrt(rand());
    ang = 2*pi*rand();
    r0 = [r*cos(ang), r*sin(ang)];
    v = [50*cos(2*pi*rand()), 50*sin(2*pi*rand())];

    fpC = struct('model','circle','maxTe',inf);
    fpH = struct('model','hex','maxTe',inf);
    fpE = struct('model','ellipse','A',A,'B',B,'theta',theta,'maxTe',inf);

    [~, Tc] = compute_time_window(r0, [0,0], R0, v, [0,0], false, false, fpC);
    [Th, ~] = compute_time_window(r0, [0,0], R0, v, [0,0], true, false, fpH);
    [Te, ~, infoE] = compute_time_window(r0, [0,0], R0, v, [0,0], true, false, fpE);

    t = (0:0.001:120).';
    pos = r0 + t*v;
    ctr = zeros(size(pos));
    [Tref, sref] = compute_reference_exit_time(pos, t, ctr, fpE);

    errs(i,1) = abs(Tc - Tref)*1e3;
    errs(i,2) = abs(Th - Tref)*1e3;
    errs(i,3) = abs(Te - Tref)*1e3;
    status(i) = string(sref);

    debug(i,:) = [r0, v, A, B, theta, Tc, Th, Te, Tref];
end

grid = linspace(0,max(errs(:))+1e-9,200).';
cdfT = table(grid,'VariableNames',{'error_ms'});
cdfT.circular = arrayfun(@(x) mean(errs(:,1)<=x), grid);
cdfT.hexagonal = arrayfun(@(x) mean(errs(:,2)<=x), grid);
cdfT.elliptical = arrayfun(@(x) mean(errs(:,3)<=x), grid);

sumT = table(["circular";"hexagonal";"elliptical"], ...
    mean(errs,1).', median(errs,1).', prctile(errs,90).', prctile(errs,95).', prctile(errs,99).', max(errs,[],1).', ...
    'VariableNames',{'predictor','mean_error_ms','median_error_ms','p90_ms','p95_ms','p99_ms','max_ms'});

writetable(cdfT, fullfile(outDir,'tstay_error_cdf.csv'));
writetable(sumT, fullfile(outDir,'tstay_error_summary.csv'));

dbg = array2table(debug, 'VariableNames', {'r0_x','r0_y','vrel_x','vrel_y','A','B','theta','T_circle','T_hex','T_ellipse','T_ref'});
dbg.status = status;
writetable(dbg, fullfile(outDir,'debug_samples.csv'));

h=figure('Visible','off'); hold on; grid on;
plot(grid,cdfT.circular,'LineWidth',1.5);
plot(grid,cdfT.hexagonal,'LineWidth',1.5);
plot(grid,cdfT.elliptical,'LineWidth',1.5);
legend({'Circular','Hexagonal','Elliptical'},'Location','southeast');
xlabel('Absolute residence-time prediction error [ms]'); ylabel('CDF');
title('Geometry debug: Tstay error CDF');
saveas(h, fullfile(outDir,'fig_tstay_error_cdf.png')); close(h);

results = struct('cdf',cdfT,'summary',sumT);
end
