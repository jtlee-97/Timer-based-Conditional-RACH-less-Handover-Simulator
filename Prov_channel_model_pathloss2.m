% Parameters
frequency = 2e9; % 2 GHz
distances = linspace(600e3, 610e3, 100); % Distance range from 600 km to 610 km
elevation_angles = [70, 80, 90]; % Elevation angles in degrees
num_trials = 2000; % Number of independent trials

% LoS probabilities for elevation angles
los_prob_values = [73.8, 82.0, 98.1]; % Percentages
los_shadow_fading = [3.5, 3.4, 2.9]; % LoS shadow fading
nlos_shadow_fading = [15.5, 13.9, 12.4]; % NLoS shadow fading
nlos_clutter_loss = [34.3, 30.9, 29.0]; % NLoS clutter loss

% Helper functions
function fspl = calculate_freespacePL(frequency, distance)
    c = 299792458; % Speed of light in m/s
    fspl = 20 * log10(frequency) + 20 * log10(distance) + 20 * log10(4 * pi / c);
end

function los_prob = get_los_prob(elevation, los_prob_values)
    index = max(1, min(round((elevation - 70) / 10) + 1, 3));
    los_prob = los_prob_values(index) / 100; % Convert to fraction
end

function [los_loss, nlos_loss] = calculate_losses(elevation, los_shadow_fading, nlos_shadow_fading, nlos_clutter_loss)
    index = max(1, min(round((elevation - 70) / 10) + 1, 3));
    los_loss = los_shadow_fading(index) * randn; % LoS shadow fading
    nlos_loss = nlos_shadow_fading(index) * randn + nlos_clutter_loss(index); % NLoS fading + clutter loss
end

% Preallocate results for trials
mean_random_trials = zeros(num_trials, length(elevation_angles));
mean_avg_trials = zeros(num_trials, length(elevation_angles));

% Perform trials
for trial = 1:num_trials
    results_random = zeros(length(distances), length(elevation_angles));
    results_avg = zeros(length(distances), length(elevation_angles));
    
    for j = 1:length(elevation_angles)
        elevation = elevation_angles(j);
        P_LOS = get_los_prob(elevation, los_prob_values); % LoS Probability
        for i = 1:length(distances)
            dist = distances(i);
            fspl = calculate_freespacePL(frequency, dist);
            
            % Calculate shadow and clutter loss
            [los_sdcl, nlos_sdcl] = calculate_losses(elevation, los_shadow_fading, nlos_shadow_fading, nlos_clutter_loss);

            % Random-based calculation
            if rand < P_LOS
                results_random(i, j) = fspl + los_sdcl;
            else
                results_random(i, j) = fspl + nlos_sdcl;
            end

            % Average-based calculation
            results_avg(i, j) = P_LOS * (fspl + los_sdcl) + (1 - P_LOS) * (fspl + nlos_sdcl);
        end
    end
    
    % Store mean values for this trial
    mean_random_trials(trial, :) = mean(results_random, 1);
    mean_avg_trials(trial, :) = mean(results_avg, 1);
end

% Calculate overall means across trials
final_mean_random = mean(mean_random_trials, 1);
final_mean_avg = mean(mean_avg_trials, 1);

% Calculate standard deviations across trials
std_random = std(mean_random_trials, 0, 1);
std_avg = std(mean_avg_trials, 0, 1);

% Display results
disp('Comparison of Mean Path Loss Values Across Trials:');
for j = 1:length(elevation_angles)
    fprintf('Elevation Angle %d°:\n', elevation_angles(j));
    fprintf('  Random Loss - Mean: %.2f dB, Std: %.2f dB\n', final_mean_random(j), std_random(j));
    fprintf('  Average Loss - Mean: %.2f dB, Std: %.2f dB\n', final_mean_avg(j), std_avg(j));
end

% Plot the results
figure;
for j = 1:length(elevation_angles)
    subplot(1, 3, j); % Create a subplot for each elevation angle
    histogram(mean_random_trials(:, j), 'FaceColor', 'r', 'DisplayName', 'Random Loss');
    hold on;
    histogram(mean_avg_trials(:, j), 'FaceColor', 'b', 'DisplayName', 'Average Loss');
    title(sprintf('Elevation Angle = %d°', elevation_angles(j)));
    xlabel('Path Loss (dB)');
    ylabel('Frequency');
    legend('show');
    grid on;
end
