clc;
clear;
close all;
results = zeros(202, 1); 
calibration_period = 35;
years = (1985:2023)';
csv_filename_pattern = 'Ensemble(4)-onsetfixed-0-flag1-1-method-0-dist-0-horizon-4-weighttype-0-yearly-mmr-deaths-world-area-%d-12-31-2019.csv';
excel_filename = 'yearly-mmr-deaths-world-12-31-2019.xlsx';

predicted_median_col = 5;
predicted_upper_col = 7;
predicted_lower_col = 6;
population_filename = 'aaaa.csv';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classificationData = readtable('Classification.xlsx', 'Sheet', 1);
regions = {"Eastern Mediterranean", "European Region", "African Region", "Western Pacific Region", "Region of the Americas", "Southeast Asia Region", "Global", "High Burden Countries"};

disp("Select a region from the following list:")
for i = 1:length(regions)
    fprintf("%d: %s\n", i, regions{i});
end
selectedIndex = input("Enter the number corresponding to your chosen region: ");
selectedRegion = regions{selectedIndex};
filteredData = classificationData(strcmp(classificationData{:, 3}, selectedRegion), :);
selectedAreas = filteredData{:, 1};
selectedCountries = filteredData{:, 2};
numAreas = length(selectedAreas);
populationData = readtable(population_filename);
excel_data = readmatrix(excel_filename);
excessDeathRates = cell(length(selectedAreas), 6);
country_spacing_factor = 0.5;  % 1.0 = normal, 2.0 = double space, 0.5 = half space

for i = 1:numAreas
area = selectedAreas(i);
countryName = selectedCountries{i};
csvFilename = sprintf(csv_filename_pattern, area);

if exist(csvFilename, 'file')
data = readmatrix(csvFilename);
years = (1985:2023)';

countryIdx = find(strcmp(populationData{:,2}, countryName));

if isempty(countryIdx)
    warning('Population data not found for country %s, skipping', countryName);
    continue;
end

countryPopulation = populationData{countryIdx, 4};

year_2020_idx = 11;  
observed_deaths_2020 = excel_data(year_2020_idx, area);
predicted_deaths_2020 = data(year_2020_idx, predicted_median_col);
predicted_upper_2020 = data(year_2020_idx, predicted_upper_col);
predicted_lower_2020 = data(year_2020_idx, predicted_lower_col);

excess_deaths_median_2020 = max(0, observed_deaths_2020 - predicted_deaths_2020) / countryPopulation * 100000;
excess_deaths_lower_2020 = max(0, observed_deaths_2020 - predicted_upper_2020) / countryPopulation * 100000;
excess_deaths_upper_2020 = max(0, observed_deaths_2020 - predicted_lower_2020) / countryPopulation * 100000;

year_2021_idx = 12;
observed_deaths_2021 = excel_data(year_2021_idx, area);
predicted_deaths_2021 = data(year_2021_idx, predicted_median_col);
predicted_upper_2021 = data(year_2021_idx, predicted_upper_col);
predicted_lower_2021 = data(year_2021_idx, predicted_lower_col);

excess_deaths_median_2021 = max(0, observed_deaths_2021 - predicted_deaths_2021) / countryPopulation * 100000;
excess_deaths_lower_2021 = max(0, observed_deaths_2021 - predicted_upper_2021) / countryPopulation * 100000;
excess_deaths_upper_2021 = max(0, observed_deaths_2021 - predicted_lower_2021) / countryPopulation * 100000;

year_2022_idx = 13;
observed_deaths_2022 = excel_data(year_2022_idx, area);
predicted_deaths_2022 = data(year_2022_idx, predicted_median_col);
predicted_upper_2022 = data(year_2022_idx, predicted_upper_col);
predicted_lower_2022 = data(year_2022_idx, predicted_lower_col);

excess_deaths_median_2022 = max(0, observed_deaths_2022 - predicted_deaths_2022) / countryPopulation * 100000;
excess_deaths_lower_2022 = max(0, observed_deaths_2022 - predicted_upper_2022) / countryPopulation * 100000;
excess_deaths_upper_2022 = max(0, observed_deaths_2022 - predicted_lower_2022) / countryPopulation * 100000;

year_2023_idx = 14;
observed_deaths_2023 = excel_data(year_2023_idx, area);
predicted_deaths_2023 = data(year_2023_idx, predicted_median_col);
predicted_upper_2023 = data(year_2023_idx, predicted_upper_col);
predicted_lower_2023 = data(year_2023_idx, predicted_lower_col);

excess_deaths_median_2023 = max(0, observed_deaths_2023 - predicted_deaths_2023) / countryPopulation * 100000;
excess_deaths_lower_2023 = max(0, observed_deaths_2023 - predicted_upper_2023) / countryPopulation * 100000;
excess_deaths_upper_2023 = max(0, observed_deaths_2023 - predicted_lower_2023) / countryPopulation * 100000;

total_excess_median = excess_deaths_median_2020 + excess_deaths_median_2021 + ...
                    excess_deaths_median_2022 + excess_deaths_median_2023;
total_excess_lower = excess_deaths_lower_2020 + excess_deaths_lower_2021 + ...
                   excess_deaths_lower_2022 + excess_deaths_lower_2023;
total_excess_upper = excess_deaths_upper_2020 + excess_deaths_upper_2021 + ...
                   excess_deaths_upper_2022 + excess_deaths_upper_2023;

excessDeathRates{i,1} = selectedCountries{i};
excessDeathRates{i,2} = [excess_deaths_median_2020, excess_deaths_lower_2020, excess_deaths_upper_2020];
excessDeathRates{i,3} = [excess_deaths_median_2021, excess_deaths_lower_2021, excess_deaths_upper_2021];
excessDeathRates{i,4} = [excess_deaths_median_2022, excess_deaths_lower_2022, excess_deaths_upper_2022];
excessDeathRates{i,5} = [excess_deaths_median_2023, excess_deaths_lower_2023, excess_deaths_upper_2023];
excessDeathRates{i,6} = [total_excess_median, total_excess_lower, total_excess_upper];
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING SECTION - Now uses the actual calculated excess death rates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

validRows = ~cellfun(@isempty, excessDeathRates(:,1));
excessDeathRates = excessDeathRates(validRows, :);

years_to_plot = 2020:2023;

for year_idx = 1:length(years_to_plot)
current_year = years_to_plot(year_idx);

baseHeight = 20 * country_spacing_factor;  
minHeight = 300 + (300 * country_spacing_factor);  
height = max(minHeight, baseHeight * size(excessDeathRates,1));
width = 800 + (400 * min(country_spacing_factor, 2));  % Cap width scaling

fig = figure('Position', [100, 100, width, height]);

year_medians = zeros(size(excessDeathRates,1), 1);
year_lowers = zeros(size(excessDeathRates,1), 1);
year_uppers = zeros(size(excessDeathRates,1), 1);

for i = 1:size(excessDeathRates,1)
if ~isempty(excessDeathRates{i, year_idx+1})
year_medians(i) = excessDeathRates{i, year_idx+1}(1);  % median
year_lowers(i) = excessDeathRates{i, year_idx+1}(2);   % lower bound
year_uppers(i) = excessDeathRates{i, year_idx+1}(3);   % upper bound
end
end

country_names = excessDeathRates(:,1);

sort_matrix = [year_medians, year_uppers, year_lowers];

[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});

sorted_countries = country_names(sort_idx);
sorted_medians = year_medians(sort_idx);
sorted_lowers = year_lowers(sort_idx);
sorted_uppers = year_uppers(sort_idx);

y_positions = 1:length(sorted_countries);

h = barh(y_positions, sorted_medians, 'FaceColor', [0.8 0.1 0.1]);
hold on;

err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);

yticks(y_positions);
font_size = max(8, 12 - country_spacing_factor);  % Adjust font size based on spacing
set(gca, 'YTickLabel', sorted_countries, 'TickLabelInterpreter', 'latex', 'FontSize', font_size);

xlabel(sprintf('Excess Death Rate per 100,000 (%d)', current_year), 'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'latex');

max_text_width = 0;
for i = 1:length(y_positions)
text_str = sprintf('$%.1f \\, [%.1f\\mbox{--}%.1f]$', sorted_medians(i), ...
              sorted_lowers(i), sorted_uppers(i));
max_text_width = max(max_text_width, length(text_str) * max(sorted_uppers) * 0.01);
end

max_data_value = max(sorted_uppers);
padding = max_data_value * 0.05; % 5% padding
text_space = max_text_width * 1.2; % Space for text labels

xlim([0, max_data_value + padding + text_space]);

for i = 1:length(y_positions)
text(sorted_uppers(i) + padding, y_positions(i), ...
 sprintf('$%.1f \\, [%.1f\\mbox{--}%.1f]$', sorted_medians(i), ...
                      sorted_lowers(i), ...
                      sorted_uppers(i)), ...
 'VerticalAlignment', 'middle', ...
 'HorizontalAlignment', 'left', ...
 'FontSize', 12, ...
 'Interpreter', 'latex');
end

grid on;
set(gca, 'YGrid', 'off');
box off;
set(gca, 'FontSize', font_size, 'LineWidth', 1.2);

left_margin = 0.15 + (0.1 * min(country_spacing_factor, 2));
set(gca, 'Position', [left_margin, 0.08, 0.95-left_margin-0.05, 0.88]);

set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperOrientation', 'portrait');
width_inches = 8 + (4 * min(country_spacing_factor, 2));  % Adjustable paper width
height_inches = height/100;  % Convert pixels to inches
set(fig, 'PaperSize', [width_inches height_inches]);
set(fig, 'PaperPosition', [0 0 width_inches height_inches]);

exportname = sprintf('ExcessDeathRates_%s_%d.pdf', selectedRegion, current_year);
print(fig, exportname, '-dpdf', '-r600');

hold off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a separate plot for the total data across all years
total_height = max(minHeight, baseHeight * size(excessDeathRates,1));
fig = figure('Position', [100, 100, width, total_height]);

% Extract total data (column 6 contains total excess death rates)
total_medians = zeros(size(excessDeathRates,1), 1);
total_lowers = zeros(size(excessDeathRates,1), 1);
total_uppers = zeros(size(excessDeathRates,1), 1);

for i = 1:size(excessDeathRates,1)
    if ~isempty(excessDeathRates{i, 6})
        total_medians(i) = excessDeathRates{i, 6}(1);  % median
        total_lowers(i) = excessDeathRates{i, 6}(2);   % lower bound
        total_uppers(i) = excessDeathRates{i, 6}(3);   % upper bound
    end
end

% Get country names
country_names = excessDeathRates(:,1);

% Create a matrix for sorting with all three criteria
sort_matrix = [total_medians, total_uppers, total_lowers];

% Custom sorting based on priorities
[~, sort_idx] = sortrows(sort_matrix, [1, 2, 3], {'ascend', 'ascend', 'ascend'});

% Apply sorting to all data
sorted_countries = country_names(sort_idx);
sorted_medians = total_medians(sort_idx);
sorted_lowers = total_lowers(sort_idx);
sorted_uppers = total_uppers(sort_idx);

% Create positions for bars
y_positions = 1:length(sorted_countries);

% Plot horizontal bars
h = barh(y_positions, sorted_medians, 'FaceColor',[0.8 0.1 0.1]);
hold on;

% Add error bars
err_neg = sorted_medians - sorted_lowers;
err_pos = sorted_uppers - sorted_medians;
errorbar(sorted_medians, y_positions, err_neg, err_pos, 'horizontal', '.k', 'LineWidth', 1.5);

% Customize plot
yticks(y_positions);
set(gca, 'YTickLabel', sorted_countries, 'TickLabelInterpreter', 'latex', 'FontSize', font_size);

% Update xlabel for total excess death rates
xlabel(sprintf('Total Excess Death Rate per 100,000 (%d-%d)', years_to_plot(1), years_to_plot(end)), 'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Calculate text width needed for labels (for total chart)
max_text_width = 0;
for i = 1:length(y_positions)
    text_str = sprintf('$%.1f \\, [%.1f\\mbox{--}%.1f]$', sorted_medians(i), ...
                      sorted_lowers(i), sorted_uppers(i));
    max_text_width = max(max_text_width, length(text_str) * max(sorted_uppers) * 0.01);
end

% Set xlim with minimal padding for total chart
max_data_value = max(sorted_uppers);
padding = max_data_value * 0.05; % 5% padding
text_space = max_text_width * 1.2; % Space for text labels

xlim([0, max_data_value + padding + text_space]);

% Add value labels with LaTeX formatting
for i = 1:length(y_positions)
    text(sorted_uppers(i) + padding, y_positions(i), ...
         sprintf('$%.1f \\, [%.1f\\mbox{--}%.1f]$', sorted_medians(i), ...
                              sorted_lowers(i), ...
                              sorted_uppers(i)), ...
         'VerticalAlignment', 'middle', ...
         'HorizontalAlignment', 'left', ...
         'FontSize', 12, ...
         'Interpreter', 'latex');
end

% Formatting
grid on;
set(gca, 'YGrid', 'off');
box off;
set(gca, 'FontSize', 11, 'LineWidth', 1.2);
set(gca, 'Position', [0.2, 0.1, 0.75, 0.85]);

% Update figure export settings for better quality
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperOrientation', 'portrait');
width_inches = 12;
height_inches = 600/100;
set(fig, 'PaperSize', [width_inches height_inches]);
set(fig, 'PaperPosition', [0 0 width_inches height_inches]);

% Export with high resolution
exportname = sprintf('ExcessDeathRates_%s_Total.pdf', selectedRegion);
print(fig, exportname, '-dpdf', '-r600');
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create formatted table for export
columnNames = {'Country'};
yearColumns = arrayfun(@(x) sprintf('Excess Death Rate (LB,UB) %d', x), years_to_plot, 'UniformOutput', false);
columnNames = [columnNames, yearColumns, {'Excess Death Rate (LB,UB) Total'}];

% Format the data with median(LB,UB) structure
formattedData = cell(size(excessDeathRates, 1), length(columnNames));
formattedData(:,1) = excessDeathRates(:,1);  % Country names

% Format each year's data and total
for i = 1:size(excessDeathRates, 1)
    for j = 2:length(columnNames)
        data_idx = j;  % Same index for both formattedData and excessDeathRates
        
        if j <= length(columnNames) && ~isempty(excessDeathRates{i,data_idx})
            formattedData{i,j} = sprintf('%.1f (%.1f, %.1f)', ...
                excessDeathRates{i,data_idx}(1), ...  % median
                excessDeathRates{i,data_idx}(2), ...  % lower bound
                excessDeathRates{i,data_idx}(3));     % upper bound
        else
            formattedData{i,j} = '';
        end
    end
end

% Create and export the formatted table
formattedTable = cell2table(formattedData, 'VariableNames', columnNames);
writetable(formattedTable, sprintf('ExcessDeathRates_%s_Formatted.xlsx', selectedRegion));