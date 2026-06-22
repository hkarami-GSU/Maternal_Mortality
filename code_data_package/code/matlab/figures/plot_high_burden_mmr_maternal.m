clear; clc; close all;

countries = {'Afghanistan','South Sudan','Chad','Nigeria', ...
             'Guinea-Bissau','Liberia','Somalia','Lesotho'};

yearStart     = 2000;
yearEnd       = 2023;

dashYear      = 2019;    % last pre-pandemic year
shadeStart    = 2020;  % start of shaded pandemic window
shadeEnd      = 2023.5;  % end of shaded pandemic window

scriptDir = fileparts(mfilename('fullpath'));
packageRoot = fullfile(scriptDir, '..', '..', '..');
mmrCsv = fullfile(packageRoot, 'data', 'processed', 'mmr_workflow', ...
    'transformed_ratio_data.csv');
maternalDeathsCsv = fullfile(packageRoot, 'data', 'processed', ...
    'maternal_deaths_workflow', 'transformed_maternal_deaths_data.csv');

plot_high_burden(mmrCsv, ...
    'MMR', 'high_burden_mmr', countries, ...
    yearStart, yearEnd, dashYear, shadeStart, shadeEnd);

plot_high_burden(maternalDeathsCsv, ...
    'Maternal Deaths', 'high_burden_maternal_deaths', countries, ...
    yearStart, yearEnd, dashYear, shadeStart, shadeEnd);


function plot_high_burden(csvPath, yLabel, outName, countries, ...
                          yearStart, yearEnd, dashYear, shadeStart, shadeEnd)

    try
        data = readtable(csvPath, 'VariableNamingRule', 'preserve');
    catch
        data = readtable(csvPath);
    end

    if ismember('Year', data.Properties.VariableNames)
        years = data{:, 'Year'};
    else
        years = data{:, 1};
    end

    if iscell(years) || isstring(years)
        years = str2double(years);
    end

    mask = years >= yearStart & years <= yearEnd;
    yearsPlot = years(mask);

    fig = figure('Color','white');

    for i = 1:numel(countries)
        subplot(2,4,i);

        countryKey = countries{i};
        if ~ismember(countryKey, data.Properties.VariableNames)
            countryKey = matlab.lang.makeValidName(countryKey);
        end
        if ~ismember(countryKey, data.Properties.VariableNames)
            error('Country not found in %s: %s', csvPath, countries{i});
        end

        y = data{mask, countryKey};

        valid = ~isnan(y);
        if any(valid)
            y_min = min(y(valid));
            y_max = max(y(valid));
        else
            y_min = 0; 
            y_max = 1;
        end

        range = y_max - y_min;
        if range == 0
            range = max(abs(y_max), 1);
        end

        y_min = y_min - 0.05 * range;
        y_max = y_max + 0.08 * range;

        % --- Shaded COVID-19 period: 2020--2023 ---
        hPatch = patch([shadeStart shadeEnd shadeEnd shadeStart], ...
                       [y_min y_min y_max y_max], ...
                       [0.85 0.85 0.85], ...
                       'EdgeColor','none', ...
                       'FaceAlpha',0.5, ...
                       'HandleVisibility','off');
        hold on

        % Put shading behind everything
        uistack(hPatch, 'bottom');

        % Plot line
        plot(yearsPlot, y, 'LineWidth', 1, 'Color', [0.3 0.3 0.3]);

        % Dashed line at 2019 = last pre-pandemic year
        line([dashYear dashYear], [y_min y_max], ...
             'Color', [0.45 0.45 0.45], ...
             'LineStyle','--', ...
             'LineWidth', 0.8);

        % Label shaded region
        x_text = (shadeStart + shadeEnd)/2;
        y_text = y_max - 0.07*(y_max - y_min);
        

        title(countries{i}, 'Interpreter','latex', 'FontSize', 6);

        if mod(i-1,4) == 0
            ylabel(yLabel, 'Interpreter','latex', 'FontSize', 6);
        end

        set(gca, ...
            'TickLabelInterpreter','latex', ...
            'FontSize', 6, ...
            'Box','on', ...
            'LineWidth', 0.5);

        xlim([yearStart yearEnd]);
        xticks([yearStart shadeStart yearEnd]);
        xticklabels({num2str(yearStart), '$\hspace{-2em}2019$', num2str(yearEnd)});
        ylim([y_min y_max]);
        hold off
    end

    set(gcf, 'Position', [100 100 1200 600]);
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, 6, 3];
    fig.PaperSize = [fig.PaperPosition(3) fig.PaperPosition(4)];
    print(fig, outName, '-dpdf', '-bestfit');
end



