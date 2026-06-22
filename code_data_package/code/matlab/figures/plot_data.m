clear; clc; close all;

% Read data from Excel file
data = readtable('Countries.xlsx');

% Define countries to plot
countries = {'India', 'Indonesia', 'China', 'Phillipine', ...
             'Pakistan', 'Nigeria', 'Bangladesh', 'DRC'};

% Define x-axis range
years = 2010:2023;

% Create figure
fig = figure('Color', 'white');

% Loop through countries
for i = 1:length(countries)
    subplot(2, 4, i)
    
    % First get the y-axis limits for the shaded area
    y_min = min(data.(countries{i}));
    y_max = max(data.(countries{i}));
    range = y_max - y_min;
    y_min = y_min - 0.05*range; % Add some padding
    y_max = y_max + 0.05*range; % Add some padding
    
    % Create gray shaded area for post-2019 (COVID-19 period)
    x_shade = [2019, 2023, 2023, 2019];
    y_shade = [y_min, y_min, y_max, y_max];
    
    % Create the shaded area first (so it's behind the line)
    patch(x_shade, y_shade, [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    
    % Hold on to add the line plot
    hold on
    
    % Plot the data line
    plot(years, data.(countries{i}), 'LineWidth', 1, 'Color', [0.3 0.3 0.3])
    
    % Add a vertical line at 2019 to mark the start of COVID-19
    line([2019, 2019], [y_min, y_max], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 0.5);
    
    title(countries{i}, 'Interpreter', 'latex', 'FontSize', 6)
    
    % Add ylabel only for leftmost plots
    if mod(i-1,4) == 0
        ylabel('TB Deaths', 'Interpreter', 'latex', 'FontSize', 6)
    end
    
    set(gca, ...
        'TickLabelInterpreter', 'latex', ...
        'FontSize', 6, ...
        'Box', 'on', ...
        'LineWidth', 0.5)
    
    xlim([2010 2023]);
    xticks([2010 2019 2023])
    ylim([y_min, y_max]);
    
    hold off
end

% Adjust figure layout
set(gcf, 'Position', [100 100 1200 600]);
fig.PaperUnits = 'inches';
fig.PaperPosition = [0, 0, 6, 3];
fig.PaperSize = [fig.PaperPosition(3) fig.PaperPosition(4)];
print(fig, 'high_burden_data', '-dpdf', '-bestfit');