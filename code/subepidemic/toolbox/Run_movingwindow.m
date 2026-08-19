clc; clear; close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTING OPTION

data_file = "input/Mydata.xlsx"; % Enter the name of the data file (.xlsx)
moving_window = 1; % Enter the moving window step
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CODE
[~, outbreakx, caddatecommon, cadregion, caddisease, datatype, DT, ...
 datevecfirst1, ~, ~, ~, ~, ~] = options();
[~, ~, forecastingperiod, weight_type] = options_forecast;
global calibrationperiod1;

data = xlsread(data_file);
data = data(:, outbreakx);

start_date = datetime(datevecfirst1);
if DT == 1
freq = 'daily';
unit = "days";
elseif DT == 7
freq = 'weekly';
unit = "weeks";
elseif DT == 365
freq = 'yearly';
unit = "years";
else
freq = 'custom';
unit = "days";
end

num_iter = ceil((length(data)-calibrationperiod1-forecastingperiod+1)/moving_window);
start_dates = datetime.empty(num_iter, 0);
caddates = strings(num_iter, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parfor i = 1:num_iter
local_start_date = start_date;
local_unit = unit;
local_moving_window = moving_window;
local_calibrationperiod1 = calibrationperiod1;
local_forecastingperiod = forecastingperiod;
local_data = data;

current_start = local_start_date + calmonths_or_weeks_or_days((i-1)*local_moving_window, local_unit);
current_end = current_start + calmonths_or_weeks_or_days(local_calibrationperiod1-1, local_unit);
caddate1 = datestr(current_end, 'mm-dd-yyyy');

filename = sprintf('input/%s-%s-%s-%s-%s', freq, caddisease, datatype, cadregion, caddate1);
data_step = local_data(1+(i-1)*local_moving_window : local_calibrationperiod1+(i-1)*local_moving_window + local_forecastingperiod, :);
trimmed_data = data_step(1:local_calibrationperiod1, :);
txt_filename = strcat(filename, '.txt');

writematrix(trimmed_data, txt_filename, 'Delimiter', '\t');
Run_Fit_subepidemicFramework(outbreakx, caddate1);
delete(txt_filename);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:num_iter
local_start_date = start_date;
local_unit = unit;
local_moving_window = moving_window;
local_calibrationperiod1 = calibrationperiod1;
local_forecastingperiod = forecastingperiod;
local_data = data;
current_start = local_start_date + ...
    calmonths_or_weeks_or_days((i-1)*local_moving_window, local_unit);
current_end = current_start + calmonths_or_weeks_or_days(local_calibrationperiod1-1, local_unit);
caddate1 = datestr(current_end, 'mm-dd-yyyy');
datevecfirst1 = current_start;
update_datevecfirst1(datevecfirst1);
[~, ~, ~, ~, ~, ~, ~, ...
~, datevecend1 , ~, ~, ~, ~] = options();
datevecend1_datetime = datetime(datevecend1(1), datevecend1(2), datevecend1(3));
forecasting_end_str = datestr(datevecend1_datetime, 'mm-dd-yyyy');
filename = sprintf('input/%s-%s-%s-%s-%s', freq, caddisease, datatype, cadregion, forecasting_end_str);
txt_filename = strcat(filename, '.txt');
data_step = local_data(1+(i-1)*local_moving_window : local_calibrationperiod1+(i-1)*local_moving_window + local_forecastingperiod, :);
writematrix(data_step, txt_filename, 'Delimiter', '\t');
plotForecast_subepidemicFramework(outbreakx, caddate1, local_forecastingperiod, weight_type);
end
disp('All fits completed.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function
function newdate = calmonths_or_weeks_or_days(n, unit)
switch unit
case "days"
newdate = caldays(n);
case "weeks"
newdate = calweeks(n);
case "years"
newdate = calyears(n);
otherwise
newdate = caldays(n); 
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_datevecfirst1(startDate)
startVec = datevec(startDate);
fileText = fileread('options.m');

startStr = sprintf('[%d %02d %02d]', startVec(1), startVec(2), startVec(3));
fileText = regexprep(fileText, 'datevecfirst1\s*=\s*\[.*?\];', ...
['datevecfirst1 = ' startStr ';']);

fid = fopen('options.m', 'w');
fwrite(fid, fileText);
fclose(fid);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


