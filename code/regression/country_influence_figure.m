function country_influence_figure(projectRoot)
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
fullModel = fitlme(T,formula,'FitMethod','ML');
C = coefficient_table(fullModel.Coefficients);
beta = C.Estimate;
se = C.SE;
countries = categories(T.country_cat);
change = nan(numel(countries),1);
for i = 1:numel(countries)
    reduced = T(T.country_cat~=countries{i},:);
    model = fitlme(reduced,formula,'FitMethod','ML');
    D = coefficient_table(model.Coefficients);
    change(i) = max(abs(D.Estimate-beta)./se);
end
[sorted,order] = sort(change,'descend');
labels = string(countries(order));
nShow = min(10,numel(labels));
fig = figure('Visible','off','Color','w','Units','pixels','Position',[100 100 720 720]);
ax = axes(fig);
barh(ax,1:nShow,sorted(1:nShow),0.52,'FaceColor',[0 0.4470 0.7410]);
ax.YTick = 1:nShow;
ax.YTickLabel = labels(1:nShow);
ax.YDir = 'reverse';
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 13;
ax.LineWidth = 1.0;
ax.XLim = [0 0.6];
ax.YLim = [0.5 nShow+0.5];
ax.XGrid = 'off';
ax.YGrid = 'off';
ax.Box = 'on';
xlabel(ax,'Influence on model coefficients','Interpreter','latex','FontSize',17);
ylabel(ax,'Country','Interpreter','latex','FontSize',17);
ax.Units = 'normalized';
ax.Position = [0.37 0.20 0.56 0.56];
pbaspect(ax,[1 1 1]);
exportgraphics(fig,fullfile(outputDir,'country_influence.pdf'),'ContentType','vector');
close(fig);
out = table(string(countries),change,'VariableNames',{'Country','Influence'});
out = sortrows(out,'Influence','descend');
writetable(out,fullfile(projectRoot,'outputs','regression','country_influence.csv'));
end

function T = coefficient_table(value)
if isa(value,'dataset')
    T = dataset2table(value);
else
    T = value;
end
end
