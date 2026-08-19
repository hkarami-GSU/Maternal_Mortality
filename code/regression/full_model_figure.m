function full_model_figure(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
dataFile = fullfile(projectRoot,'outputs','regression','full_model_analysis_data.csv');
outputDir = fullfile(projectRoot,'outputs','regression','final_figure');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
T = readtable(dataFile);
T.country_cat = categorical(T.country);
T.year_cat = categorical(T.year);
formula = ['log_obs_expected ~ anc_disruption_num + delivery_disruption_num + pnc_disruption_num + log_baseline_mmr + anc4_pre2020_pct + sba_pre2020_pct + year_cat + (1|country_cat)'];
model = fitlme(T,formula,'FitMethod','ML');
C = coefficient_table(model.Coefficients);
names = string(C.Name);
target = ["anc4_pre2020_pct","sba_pre2020_pct","anc_disruption_num","delivery_disruption_num","pnc_disruption_num","log_baseline_mmr","year_cat_2022"];
labels = {'$\mathrm{Antenatal\ care\ coverage}$','$\mathrm{Skilled\ birth\ attendance}$','$\mathrm{Antenatal\ care\ disruption}$','$\mathrm{Facility\!\!-based\ delivery\ disruption}$','$\mathrm{Postnatal\ care\ disruption}$','$\mathrm{Baseline\ maternal\ mortality}$','$2022\ (\mathrm{reference:}\ 2021)$'};
index = zeros(numel(target),1);
for i = 1:numel(target)
    hit = find(names==target(i));
    assert(numel(hit)==1,'Could not find coefficient %s',target(i));
    index(i) = hit;
end
estimate = C.Estimate(index);
lower = C.Lower(index);
upper = C.Upper(index);
x = 1:numel(estimate);
fig = figure('Visible','off','Color','w','Position',[100 100 850 850]);
ax = axes(fig);
ax.Position = [0.18 0.39 0.78 0.57];
errorbar(ax,x,estimate,estimate-lower,upper-estimate,'o','LineWidth',1.7,'MarkerSize',9);
hold(ax,'on');
yline(ax,0,'--','LineWidth',1.0,'Color',[0.3 0.3 0.3]);
ax.XTick = x;
ax.XTickLabel = labels;
ax.XTickLabelRotation = 90;
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 17;
ax.LineWidth = 1.0;
ax.TickDir = 'out';
ax.XGrid = 'off';
ax.YGrid = 'off';
ax.YLim = [min(lower)-0.02 max(upper)+0.02];
box(ax,'on');
ylabel(ax,'$\mathrm{Coefficients}\ (95\%\ \mathrm{CI})$','Interpreter','latex','FontSize',21);
exportgraphics(fig,fullfile(outputDir,'full_model_coefficients.pdf'),'ContentType','vector');
close(fig);
writetable(C,fullfile(projectRoot,'outputs','regression','full_model_coefficients.csv'));
fit = table(model.NumObservations,model.ModelCriterion.AIC,model.ModelCriterion.BIC,model.LogLikelihood,'VariableNames',{'Observations','AIC','BIC','LogLikelihood'});
writetable(fit,fullfile(projectRoot,'outputs','regression','full_model_fit_statistics.csv'));
end

function T = coefficient_table(value)
if isa(value,'dataset')
    T = dataset2table(value);
else
    T = value;
end
end
