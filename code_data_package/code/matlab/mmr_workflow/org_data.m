% MATLAB Code to Transform Excel Data to Year-Country Matrix
% Input: Excel file with columns: Indicator, Location, Period, FactValueNumeric
% Output: Matrix with years (1985-2023) as rows and countries as columns

function transformExcelData()
    % Read the Excel file
    filename = 'ratio.xlsx';
    
    try
        % Read data from Excel file
        data = readtable(filename);
        
        % Display original data structure
        fprintf('Original data structure:\n');
        disp(head(data));
        fprintf('Total rows: %d\n\n', height(data));
        
        % Extract unique years and countries
        years = unique(data.Period);
        countries = unique(data.Location);
        
        % Sort years and countries
        years = sort(years);
        countries = sort(countries); % Alphabetical order
        
        % Create year range from 1985 to 2023
        full_year_range = (1985:2023)';
        
        % Initialize the output matrix with NaN values
        % Rows: years (1985-2023), Columns: countries (alphabetical)
        output_matrix = NaN(length(full_year_range), length(countries));
        
        % Create the output table structure
        country_names = countries;
        
        % Fill the matrix with data
        for i = 1:height(data)
            year = data.Period(i);
            country = data.Location{i};
            value = data.FactValueNumeric(i);
            
            % Find indices
            year_idx = find(full_year_range == year);
            country_idx = find(strcmp(countries, country));
            
            if ~isempty(year_idx) && ~isempty(country_idx)
                output_matrix(year_idx, country_idx) = value;
            end
        end
        
        % Create output table
        output_table = array2table(output_matrix, 'VariableNames', countries, ...
                                 'RowNames', cellstr(num2str(full_year_range)));
        
        % Add year column as first column
        output_table = addvars(output_table, full_year_range, 'Before', 1, 'NewVariableNames', 'Year');
        
        % Display results
        fprintf('Transformed data structure:\n');
        fprintf('Years: %d to %d (%d years)\n', min(full_year_range), max(full_year_range), length(full_year_range));
        fprintf('Countries: %d countries (alphabetically sorted)\n', length(countries));
        fprintf('Matrix size: %d x %d\n\n', size(output_matrix, 1), size(output_matrix, 2));
        
        % Show first few rows and columns
        fprintf('Sample of transformed data (first 10 years, first 5 countries):\n');
        sample_table = output_table(1:min(10, height(output_table)), 1:min(6, width(output_table)));
        disp(sample_table);
        
        % Save to new Excel file
        output_filename = 'transformed_ratio_data.xlsx';
        writetable(output_table, output_filename);
        fprintf('\nTransformed data saved to: %s\n', output_filename);
        
        % Optional: Save as CSV for easier viewing
        csv_filename = 'transformed_ratio_data.csv';
        writetable(output_table, csv_filename);
        fprintf('Also saved as CSV: %s\n', csv_filename);
        
        % Display summary statistics
        fprintf('\nSummary Statistics:\n');
        fprintf('Total data points: %d\n', sum(~isnan(output_matrix(:))));
        fprintf('Missing data points: %d\n', sum(isnan(output_matrix(:))));
        fprintf('Coverage: %.1f%%\n', 100 * sum(~isnan(output_matrix(:))) / numel(output_matrix));
        
        % Show countries list
        fprintf('\nCountries in alphabetical order:\n');
        for i = 1:length(countries)
            fprintf('%d. %s\n', i, countries{i});
        end
        
    catch ME
        fprintf('Error reading file: %s\n', ME.message);
        fprintf('Please ensure the file "ratio.xlsx" exists in the current directory.\n');
        fprintf('Expected columns: Indicator, Location, Period, FactValueNumeric\n');
    end
end

% Alternative function if you want to return the data instead of saving
function [output_table, years, countries] = getTransformedData(filename)
    % Read and transform data, return as variables
    
    data = readtable(filename);
    
    % Extract and sort unique values
    years = sort(unique(data.Period));
    countries = sort(unique(data.Location));
    
    % Create full year range
    full_year_range = (1985:2023)';
    
    % Initialize matrix
    output_matrix = NaN(length(full_year_range), length(countries));
    
    % Fill matrix
    for i = 1:height(data)
        year = data.Period(i);
        country = data.Location{i};
        value = data.FactValueNumeric(i);
        
        year_idx = find(full_year_range == year);
        country_idx = find(strcmp(countries, country));
        
        if ~isempty(year_idx) && ~isempty(country_idx)
            output_matrix(year_idx, country_idx) = value;
        end
    end
    
    % Create output table
    output_table = array2table(output_matrix, 'VariableNames', countries);
    output_table = addvars(output_table, full_year_range, 'Before', 1, 'NewVariableNames', 'Year');
    
    years = full_year_range;
end

% Run the main function
transformExcelData();