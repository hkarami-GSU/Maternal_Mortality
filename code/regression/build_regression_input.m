function build_regression_input(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
inputFile = fullfile(projectRoot,'data','processed','regression','maternal_regression_data.xlsx');
outputDir = fullfile(projectRoot,'outputs','regression');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
T = readtable(inputFile,'Sheet','RegressionReady','VariableNamingRule','preserve');
required = {'iso3','country','year','log_obs_expected','anc_disruption','delivery_disruption','pnc_disruption','baseline_mmr_2019','anc4_pre2020_pct','sba_pre2020_pct'};
for i = 1:numel(required)
    assert(ismember(required{i},T.Properties.VariableNames),'Missing required variable: %s',required{i});
end
anc = disruption_code(string(T.anc_disruption));
delivery = disruption_code(string(T.delivery_disruption));
pnc = disruption_code(string(T.pnc_disruption));
R = table(string(T.iso3),string(T.country),double(T.year),double(T.log_obs_expected),string(T.anc_disruption),anc,string(T.delivery_disruption),delivery,string(T.pnc_disruption),pnc,double(T.baseline_mmr_2019),log(double(T.baseline_mmr_2019)),double(T.anc4_pre2020_pct),double(T.sba_pre2020_pct),'VariableNames',{'iso3','country','year','log_obs_expected','anc_disruption','anc_disruption_num','delivery_disruption','delivery_disruption_num','pnc_disruption','pnc_disruption_num','baseline_mmr_2019','log_baseline_mmr','anc4_pre2020_pct','sba_pre2020_pct'});
assert(all(isfinite(R.log_obs_expected)),'Outcome contains missing or nonfinite values.');
assert(all(isfinite(R{:,6})) && all(isfinite(R{:,8})) && all(isfinite(R{:,10})),'Disruption coding is incomplete.');
writetable(R,fullfile(outputDir,'full_model_analysis_data.csv'));
end

function values = disruption_code(labels)
values = nan(numel(labels),1);
values(labels=="Increase of 5% or more") = 0;
values(labels=="Less than 5% (including 0%)") = 0;
values(labels=="5-25%") = 1;
values(labels=="26-50%") = 2;
values(labels=="More than 50%") = 3;
end
