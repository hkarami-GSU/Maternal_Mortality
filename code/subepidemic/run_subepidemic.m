function run_subepidemic(projectRoot,outcome,errorModel,areas)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
if nargin < 2 || isempty(outcome)
    outcome = 'mmr';
end
if nargin < 3 || isempty(errorModel)
    errorModel = 'normal';
end
if nargin < 4 || isempty(areas)
    areas = 'all';
end
setenv('MATERNAL_PROJECT_ROOT',projectRoot);
setenv('MATERNAL_OUTCOME',outcome);
setenv('MATERNAL_ERROR_MODEL',errorModel);
toolboxDir = fullfile(projectRoot,'code','subepidemic','toolbox');
oldDir = pwd;
cleanupDir = onCleanup(@() cd(oldDir));
cd(toolboxDir);
[~,~,dateTag,regionTag,diseaseTag,dataType,DT,~,~,~,~,~,~] = options;
[~,~,forecastHorizon,weightType] = options_forecast;
global calibrationperiod1
if strcmp(diseaseTag,'mmr')
    dataFile = fullfile(projectRoot,'data','source','mmeig','yearly-mmr-deaths-world-01-01-2023.txt');
else
    dataFile = fullfile(projectRoot,'data','source','mmeig','yearly-maternal-deaths-world-01-01-2023.txt');
end
assert(isfile(dataFile),'Input file not found: %s',dataFile);
data = readmatrix(dataFile,'FileType','text');
if ischar(areas) || isstring(areas)
    if strcmpi(string(areas),'all')
        areas = 1:size(data,2);
    else
        error('areas must be a numeric vector or all.');
    end
end
areas = unique(double(areas(:)'));
assert(all(areas >= 1 & areas <= size(data,2)),'Area index is outside the data range.');
if ~exist('input','dir')
    mkdir('input');
end
if ~exist('output','dir')
    mkdir('output');
end
if DT == 365
    frequency = 'yearly';
elseif DT == 7
    frequency = 'weekly';
else
    frequency = 'daily';
end
inputFile = fullfile('input',sprintf('%s-%s-%s-%s-%s.txt',frequency,diseaseTag,dataType,regionTag,dateTag));
writematrix(data(1:calibrationperiod1,:),inputFile,'Delimiter','tab');
useParallel = license('test','Distrib_Computing_Toolbox') && numel(areas) > 1;
if useParallel
    pool = gcp('nocreate');
    if isempty(pool)
        workers = max(1,feature('numcores')-1);
        parpool(workers);
    end
    parfor k = 1:numel(areas)
        Run_Fit_subepidemicFramework(areas(k),dateTag);
    end
else
    for k = 1:numel(areas)
        Run_Fit_subepidemicFramework(areas(k),dateTag);
    end
end
writematrix(data,inputFile,'Delimiter','tab');
if useParallel
    parfor k = 1:numel(areas)
        plotForecast_subepidemicFramework(areas(k),dateTag,forecastHorizon,weightType);
    end
else
    for k = 1:numel(areas)
        plotForecast_subepidemicFramework(areas(k),dateTag,forecastHorizon,weightType);
    end
end
fprintf('%s, %s: %d area(s) completed.\n',outcome,errorModel,numel(areas));
end
