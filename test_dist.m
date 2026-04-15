% Data for RURAL, SUBURBAN at idx = 8 (corresponding to 80 degrees elevation)
idx = 8;
los_sw = [1.79, 1.14, 1.14, 0.92, 1.42, 1.56, 0.85, 0.72, 0.72];
nlos_sw = [8.93, 9.08, 8.78, 10.25, 10.56, 10.74, 10.17, 11.52, 11.52];
nlos_cl = [19.52, 18.17, 18.42, 18.28, 18.63, 17.68, 16.50, 16.30, 16.30];

% Generate distributions for both methods

% First method (commented out)
%a_method1 = (-los_sw(idx)) + (2 * los_sw(idx)) * rand(1, 1000);
b_method1 = (-nlos_sw(idx)) + (2 * nlos_sw(idx)) * rand(1, 1000) + nlos_cl(idx);

% Second method (current method using randn)
a_method2 = los_sw(idx) * randn(1, 1000);
b_method2 = nlos_sw(idx) * randn(1, 1000) + nlos_cl(idx);

% Plotting the distributions
figure;

% LoS for both methods
subplot(1, 2, 1);
histogram(a_method1, 30, 'FaceAlpha', 0.5, 'FaceColor', 'r', 'DisplayName', 'Method 1 (LoS)', 'EdgeColor', 'none');
hold on;
histogram(a_method2, 30, 'FaceAlpha', 0.5, 'FaceColor', 'b', 'DisplayName', 'Method 2 (LoS)', 'EdgeColor', 'none');
title('LoS Shadow Fading Distribution (Elevation = 80°)');
xlabel('Shadow Fading (dB)');
ylabel('Frequency');
legend;

% NLoS for both methods
subplot(1, 2, 2);
histogram(b_method1, 30, 'FaceAlpha', 0.5, 'FaceColor', 'r', 'DisplayName', 'Method 1 (NLoS)', 'EdgeColor', 'none');
hold on;
histogram(b_method2, 30, 'FaceAlpha', 0.5, 'FaceColor', 'b', 'DisplayName', 'Method 2 (NLoS)', 'EdgeColor', 'none');
title('NLoS Shadow Fading + Clutter Loss Distribution (Elevation = 80°)');
xlabel('Shadow Fading + Clutter Loss (dB)');
ylabel('Frequency');
legend;
