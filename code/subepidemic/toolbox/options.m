function [cumulative1,outbreakx,caddate1,cadregion,caddisease,datatype,DT,datevecfirst1,datevecend1,numstartpoints,topmodelsx,B,flag1] = options
global method1 npatches_fixed onset_fixed dist1 smoothfactor1 calibrationperiod1
outcome = lower(strtrim(getenv('MATERNAL_OUTCOME')));
if isempty(outcome)
    outcome = 'mmr';
end
errorModel = lower(strtrim(getenv('MATERNAL_ERROR_MODEL')));
if isempty(errorModel)
    errorModel = 'normal';
end
areaValue = str2double(getenv('MATERNAL_AREA'));
if isnan(areaValue) || areaValue < 1
    areaValue = 1;
end
cumulative1 = 0;
outbreakx = areaValue;
caddate1 = '01-01-2019';
cadregion = 'world';
datatype = 'deaths';
DT = 365;
datevecfirst1 = [2000 1 1];
datevecend1 = [2019 1 1];
numstartpoints = 30;
topmodelsx = 4;
B = 300;
flag1 = 1;
method1 = 0;
npatches_fixed = 2;
onset_fixed = 0;
smoothfactor1 = 1;
calibrationperiod1 = 20;
if strcmp(outcome,'mmr')
    caddisease = 'mmr';
elseif any(strcmp(outcome,{'maternal_deaths','maternal'}))
    caddisease = 'maternal';
else
    error('MATERNAL_OUTCOME must be mmr or maternal_deaths.');
end
if strcmp(errorModel,'normal')
    dist1 = 0;
elseif strcmp(errorModel,'poisson')
    dist1 = 1;
else
    error('MATERNAL_ERROR_MODEL must be normal or poisson.');
end
end
