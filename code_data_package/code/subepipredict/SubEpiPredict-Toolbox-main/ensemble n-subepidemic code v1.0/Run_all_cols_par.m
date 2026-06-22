clc;clear;close all;
toolbox_dir = fileparts(mfilename('fullpath'));
cd(toolbox_dir);
run('options.m');options_forecast;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ATTENTION: SETTING OPTIONS
[~, ~, caddatecommon, cadregion, caddisease, datatype, DT, ...
 ~, ~, ~, ~, ~, ~] = options();

repo_root = fullfile(toolbox_dir, '..', '..', '..', '..');
switch caddisease
    case 'mmr'
        data_file = fullfile(repo_root, 'data', 'raw', 'mmr_workflow', ...
            'yearly-mmr-deaths-world-01-01-2023.txt');
    case 'maternal'
        data_file = fullfile(repo_root, 'data', 'raw', 'maternal_deaths_workflow', ...
            'yearly-maternal-deaths-world-01-01-2023.txt');
    otherwise
        error('Unsupported study workflow caddisease value: %s', caddisease);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CODE  
[~, ~, forecastingperiod, weight_type] = options_forecast;

% Access global variable for calibration period
global calibrationperiod1;

if ~exist('input','dir')
    mkdir('input');
end
if ~exist('output','dir')
    mkdir('output');
end

data = readmatrix(data_file, 'FileType', 'text');
outbreakx_range = 1:size(data, 2);
trimmed_data = data(1:calibrationperiod1, :);
dateobj = datetime(caddatecommon, 'InputFormat', 'MM-dd-yyyy');
if DT == 1
    freq = 'daily';
elseif DT == 7
    freq = 'weekly';
elseif DT == 365
    freq = 'yearly';
else
    freq = 'custom';
end
filename = sprintf('input/%s-%s-%s-%s-%s', ...
    freq, caddisease, datatype, cadregion, datestr(dateobj, 'mm-dd-yyyy'));

txt_filename = strcat(filename, '.txt');
writematrix(trimmed_data, txt_filename, 'Delimiter', '\t');


maxWorkers = feature('numcores');
numWorkers = max(1, maxWorkers - 1);
poolobj = gcp('nocreate');
if isempty(poolobj)
parpool(numWorkers);
end

parfor i = 1:length(outbreakx_range)
outbreakx_pass = outbreakx_range(i);
%try
Run_Fit_subepidemicFramework(outbreakx_pass, caddatecommon);
%catch ME
% fprintf('Error at outbreakx = %d: %s\n', outbreakx_pass, ME.message);
% end
end

%%%%%%
delete(txt_filename);
writematrix(data, txt_filename, 'Delimiter', '\t');
%%%%%%

parfor i = 1:length(outbreakx_range)
outbreakx_pass = outbreakx_range(i);
try
plotForecast_subepidemicFramework(outbreakx_pass,caddatecommon,...
    forecastingperiod,weight_type)
catch ME
fprintf('Error at outbreakx = %d: %s\n', outbreakx_pass, ME.message);
end
end

disp('All fits completed.');
