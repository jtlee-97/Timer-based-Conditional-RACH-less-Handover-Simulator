% Parameters
frequency = 2e9; % 2 GHz
distances = linspace(600e3, 610e3, 100); % Distance range from 600 km to 610 km
elevation_angles = [70, 80, 90]; % Elevation angles in degrees

% LoS probabilities for elevation angles
los_prob_values = [73.8, 82.0, 98.1]; % Percentages
los_shadow_fading = [3.5, 3.4, 2.9]; % LoS shadow fading
nlos_shadow_fading = [15.5, 13.9, 12.4]; % NLoS shadow fading
nlos_clutter_loss = [34.3, 30.9, 29.0]; % NLoS clutter loss

% Preallocate results
results_random = zeros(length(distances), length(elevation_angles));
results_avg = zeros(length(distances), length(elevation_angles));

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

% Simulation
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

% Calculate mean values
mean_random = mean(results_random, 1);
mean_avg = mean(results_avg, 1);

% Plot the results with subplots
figure;
for j = 1:length(elevation_angles)
    subplot(1, 3, j); % Create a subplot for each elevation angle
    plot(distances, results_random(:, j), 'r--', 'DisplayName', 'Random Loss');
    hold on;
    plot(distances, results_avg(:, j), 'b-', 'DisplayName', 'Average Loss');
    xlabel('Distance (m)');
    ylabel('Path Loss (dB)');
    title(sprintf('Elevation Angle = %d°', elevation_angles(j)));
    legend('show');
    grid on;
    
    % Display mean values in the title
    text(605e3, mean_avg(j) + 5, sprintf('Mean Avg: %.2f dB\nMean Rand: %.2f dB', ...
        mean_avg(j), mean_random(j)), 'FontSize', 8);
end

% Show mean values in the command window
disp('Mean Path Loss Values:');
for j = 1:length(elevation_angles)
    fprintf('Elevation Angle %d° - Mean Random Loss: %.2f dB, Mean Average Loss: %.2f dB\n', ...
        elevation_angles(j), mean_random(j), mean_avg(j));
end
