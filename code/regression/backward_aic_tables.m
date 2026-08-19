function backward_aic_tables(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
dataFile = fullfile(projectRoot,'outputs','regression','full_model_analysis_data.csv');
outputDir = fullfile(projectRoot,'outputs','regression','final_tables');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
T = readtable(dataFile);
T.country_cat = categorical(T.country);
T.year_cat = categorical(T.year);
removable = {'anc_disruption_num','delivery_disruption_num','pnc_disruption_num','log_baseline_mmr','anc4_pre2020_pct','sba_pre2020_pct'};
terms = [removable {'year_cat'}];
makeFormula = @(x) ['log_obs_expected ~ ' strjoin(x,' + ') ' + (1|country_cat)'];
fullModel = fitlme(T,makeFormula(terms),'FitMethod','ML');
fullAIC = fullModel.ModelCriterion.AIC;
currentModel = fullModel;
currentAIC = fullAIC;
stepNumber = zeros(0,1);
removed = strings(0,1);
aicPath = zeros(0,1);
step = 0;
while true
    candidates = intersect(terms,removable,'stable');
    if isempty(candidates)
        break;
    end
    values = nan(numel(candidates),1);
    for j = 1:numel(candidates)
        test = terms;
        test(strcmp(test,candidates{j})) = [];
        model = fitlme(T,makeFormula(test),'FitMethod','ML');
        values(j) = model.ModelCriterion.AIC;
    end
    [best,bestIndex] = min(values);
    if best >= currentAIC
        break;
    end
    step = step+1;
    term = candidates{bestIndex};
    terms(strcmp(terms,term)) = [];
    currentModel = fitlme(T,makeFormula(terms),'FitMethod','ML');
    currentAIC = currentModel.ModelCriterion.AIC;
    stepNumber(end+1,1) = step;
    removed(end+1,1) = pretty_name(term);
    aicPath(end+1,1) = currentAIC;
end
C = coefficient_table(currentModel.Coefficients);
C = C(string(C.Name)~="(Intercept)",:);
predictor = strings(height(C),1);
coefficient = strings(height(C),1);
interval = strings(height(C),1);
pValue = strings(height(C),1);
for i = 1:height(C)
    predictor(i) = pretty_name(string(C.Name(i)));
    coefficient(i) = sprintf('%.4f',C.Estimate(i));
    interval(i) = sprintf('[%.4f, %.4f]',C.Lower(i),C.Upper(i));
    if C.pValue(i)<0.001
        pValue(i) = '<0.001';
    else
        pValue(i) = sprintf('%.3f',C.pValue(i));
    end
end
mainTable = table(predictor,coefficient,interval,pValue,'VariableNames',{'Predictor','Coefficient','CI_95','p_value'});
writetable(mainTable,fullfile(outputDir,'main_selected_model_table.csv'));
pathTable = table([0;stepNumber],["Full model";removed],[fullAIC;aicPath],'VariableNames',{'Step','Change','AIC'});
writetable(pathTable,fullfile(outputDir,'supplementary_selection_path.csv'));
write_main_tex(mainTable,fullAIC,currentModel.ModelCriterion.AIC,fullfile(outputDir,'main_selected_model_table.tex'));
write_path_tex(pathTable,fullfile(outputDir,'supplementary_selection_path.tex'));
end

function write_main_tex(T,fullAIC,selectedAIC,file)
fid = fopen(file,'w');
fprintf(fid,'\\begin{table}[!ht]\n\\centering\n\\caption{Predictors retained in the selected model.}\n\\begin{tabular}{lccc}\n\\hline\nPredictor & Coefficient & 95\\%% CI & $p$-value \\\\\n\\hline\n');
for i = 1:height(T)
    fprintf(fid,'%s & %s & %s & %s \\\\\n',T.Predictor(i),T.Coefficient(i),T.CI_95(i),T.p_value(i));
end
fprintf(fid,'\\hline\n\\multicolumn{4}{l}{Full model AIC = %.2f; selected model AIC = %.2f.}\\\\\n\\end{tabular}\n\\end{table}\n',fullAIC,selectedAIC);
fclose(fid);
end

function write_path_tex(T,file)
fid = fopen(file,'w');
fprintf(fid,'\\begin{table}[!ht]\n\\centering\n\\caption{Backward AIC selection path.}\n\\begin{tabular}{clc}\n\\hline\nStep & Change & AIC \\\\\n\\hline\n');
for i = 1:height(T)
    fprintf(fid,'%d & %s & %.2f \\\\\n',T.Step(i),T.Change(i),T.AIC(i));
end
fprintf(fid,'\\hline\n\\end{tabular}\n\\end{table}\n');
fclose(fid);
end

function label = pretty_name(term)
switch string(term)
    case "anc_disruption_num"
        label = "Antenatal care disruption";
    case "delivery_disruption_num"
        label = "Facility-based delivery disruption";
    case "pnc_disruption_num"
        label = "Postnatal care disruption";
    case "log_baseline_mmr"
        label = "Baseline maternal mortality";
    case "anc4_pre2020_pct"
        label = "Antenatal care coverage";
    case "sba_pre2020_pct"
        label = "Skilled birth attendance";
    case "year_cat_2022"
        label = "2022 (reference: 2021)";
    otherwise
        label = string(term);
end
end

function T = coefficient_table(value)
if isa(value,'dataset')
    T = dataset2table(value);
else
    T = value;
end
end
