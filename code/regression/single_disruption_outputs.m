function single_disruption_outputs(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
dataFile = fullfile(projectRoot,'outputs','regression','full_model_analysis_data.csv');
outputDir = fullfile(projectRoot,'outputs','regression','final_single_disruption');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
T = readtable(dataFile);
T.country_cat = categorical(T.country);
T.year_cat = categorical(T.year);
labels = {'Antenatal care disruption','Facility-based delivery disruption','Postnatal care disruption'};
terms = {'anc_disruption_num','delivery_disruption_num','pnc_disruption_num'};
estimate = nan(3,1);
lower = nan(3,1);
upper = nan(3,1);
pValue = nan(3,1);
for i = 1:3
    formula = ['log_obs_expected ~ ' terms{i} ' + log_baseline_mmr + anc4_pre2020_pct + sba_pre2020_pct + year_cat + (1|country_cat)'];
    model = fitlme(T,formula,'FitMethod','ML');
    C = coefficient_table(model.Coefficients);
    hit = find(string(C.Name)==string(terms{i}));
    estimate(i) = C.Estimate(hit);
    lower(i) = C.Lower(hit);
    upper(i) = C.Upper(hit);
    pValue(i) = C.pValue(hit);
end
fig = figure('Visible','off','Color','w','Position',[100 100 700 700]);
errorbar(1:3,estimate,estimate-lower,upper-estimate,'o','LineWidth',1.6,'MarkerSize',8);
hold on;
yline(0,'--','LineWidth',1.0,'Color',[0.3 0.3 0.3]);
set(gca,'XTick',1:3,'XTickLabel',labels,'XTickLabelRotation',90,'TickLabelInterpreter','latex','FontSize',15,'LineWidth',1.0,'XGrid','off','YGrid','off');
ylabel('Coefficients (95\% CI)','Interpreter','latex','FontSize',18);
box on;
exportgraphics(fig,fullfile(outputDir,'single_disruption_effects.pdf'),'ContentType','vector');
close(fig);
R = table(string(labels(:)),estimate,lower,upper,pValue,'VariableNames',{'Predictor','Coefficient','Lower95CI','Upper95CI','PValue'});
writetable(R,fullfile(outputDir,'single_disruption_results.csv'));
fid = fopen(fullfile(outputDir,'single_disruption_results.tex'),'w');
fprintf(fid,'\\begin{tabular}{lccc}\n\\hline\nPredictor & Coefficient & 95\\%% CI & $p$-value \\\\ \n\\hline\n');
for i = 1:height(R)
    fprintf(fid,'%s & %.3f & [%.3f, %.3f] & %.3f \\\\ \n',R.Predictor(i),R.Coefficient(i),R.Lower95CI(i),R.Upper95CI(i),R.PValue(i));
end
fprintf(fid,'\\hline\n\\end{tabular}\n');
fclose(fid);
end

function T = coefficient_table(value)
if isa(value,'dataset')
    T = dataset2table(value);
else
    T = value;
end
end
