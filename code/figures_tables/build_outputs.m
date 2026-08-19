function build_outputs(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
modelDir = fullfile(projectRoot,'outputs','model_results');
tableDir = fullfile(projectRoot,'outputs','tables');
mainFigDir = fullfile(projectRoot,'outputs','figures','main');
suppFigDir = fullfile(projectRoot,'outputs','figures','supplementary');
if ~exist(tableDir,'dir'); mkdir(tableDir); end
if ~exist(mainFigDir,'dir'); mkdir(mainFigDir); end
if ~exist(suppFigDir,'dir'); mkdir(suppFigDir); end
mmr = readtable(fullfile(modelDir,'forecast_mmr_country_year.csv'),'VariableNamingRule','preserve');
deaths = readtable(fullfile(modelDir,'forecast_maternal_deaths_country_year.csv'),'VariableNamingRule','preserve');
classification = readtable(fullfile(projectRoot,'data','source','mmeig','Classification.xlsx'),'VariableNamingRule','preserve');
classification = sortrows(classification,'Number');
summary = build_country_summary(mmr,deaths,classification);
writetable(summary,fullfile(tableDir,'country_level_excess_summary.csv'));
highPlot = ["Afghanistan","South Sudan","Chad","Nigeria","Guinea-Bissau","Liberia","Somalia","Lesotho"];
highTable = ["Afghanistan","Chad","Guinea-Bissau","Lesotho","Liberia","Nigeria","Somalia","South Sudan"];
write_high_burden_table(mmr,highTable,fullfile(tableDir,'table1_high_burden_excess_mmr.csv'),fullfile(tableDir,'table1_high_burden_excess_mmr.tex'));
write_high_burden_table(deaths,highTable,fullfile(tableDir,'table2_high_burden_excess_maternal_deaths.csv'),fullfile(tableDir,'table2_high_burden_excess_maternal_deaths.tex'));
write_region_table(summary,fullfile(tableDir,'table3_global_regional_summary.csv'),fullfile(tableDir,'table3_global_regional_summary.tex'));
plot_forecast_panels(mmr,highPlot,'MMR',fullfile(mainFigDir,'High_Burden_Countries_mmr.pdf'));
plot_forecast_panels(deaths,highPlot,'Maternal deaths',fullfile(suppFigDir,'High_Burden_Countries_maternaldeaths.pdf'));
regions = ["Southeast Asia Region","European Region","Eastern Mediterranean","African Region","Western Pacific Region","Region of the Americas"];
for r = 1:numel(regions)
    region = regions(r);
    countries = string(classification.Country(string(classification.Region)==region));
    plot_forecast_panels(deaths,countries,'Maternal deaths',fullfile(suppFigDir,region + "_maternaldeaths.pdf"));
    plot_forecast_panels(mmr,countries,'MMR',fullfile(suppFigDir,region + "_mmr.pdf"));
    for year = 2020:2023
        plot_excess_bar(deaths,countries,year,'Excess maternal deaths',fullfile(suppFigDir,"ExcessMaternalDeaths_" + region + "_" + year + ".pdf"));
        plot_excess_bar(mmr,countries,year,'Excess MMR',fullfile(suppFigDir,"ExcessDeaths_" + region + "_" + year + ".pdf"));
    end
    plot_excess_bar(deaths,countries,'Total','Total excess maternal deaths (2020-2023)',fullfile(suppFigDir,"ExcessMaternalDeaths_" + region + "_Total.pdf"));
    plot_excess_bar(mmr,countries,'Total','Aggregate excess MMR (2020-2023)',fullfile(suppFigDir,"ExcessDeaths_" + region + "_Total.pdf"));
end
plot_excess_bar(deaths,highPlot,'Total','Total excess maternal deaths (2020-2023)',fullfile(suppFigDir,'ExcessMaternalDeaths_High Burden Countries_Total.pdf'));
plot_excess_bar(mmr,highPlot,'Total','Aggregate excess MMR (2020-2023)',fullfile(suppFigDir,'ExcessDeaths_High Burden Countries_Total.pdf'));
mapMmr = table(summary.country,summary.mmr_total_median_rounded,'VariableNames',{'country','value'});
mapDeaths = table(summary.country,summary.deaths_total_median_rounded,'VariableNames',{'country','value'});
writetable(mapMmr,fullfile(tableDir,'map_ready_mmr.csv'));
writetable(mapDeaths,fullfile(tableDir,'map_ready_maternal_deaths.csv'));
fprintf('Tables and figures written to %s and %s.\n',tableDir,fullfile(projectRoot,'outputs','figures'));
end

function summary = build_country_summary(mmr,deaths,classification)
n = height(classification);
area = classification.Number;
country = string(classification.Country);
region = string(classification.Region);
deathsMedian = zeros(n,1);
deathsLower = zeros(n,1);
deathsUpper = zeros(n,1);
mmrMedian = zeros(n,1);
mmrLower = zeros(n,1);
mmrUpper = zeros(n,1);
for i = 1:n
    d = deaths(deaths.area==area(i) & deaths.year>=2020,:);
    m = mmr(mmr.area==area(i) & mmr.year>=2020,:);
    deathsMedian(i) = round(sum(d.excess_median,'omitnan'));
    deathsLower(i) = round(sum(d.excess_lower,'omitnan'));
    deathsUpper(i) = round(sum(d.excess_upper,'omitnan'));
    mmrMedian(i) = round(sum(m.excess_median,'omitnan'));
    mmrLower(i) = round(sum(m.excess_lower,'omitnan'));
    mmrUpper(i) = round(sum(m.excess_upper,'omitnan'));
end
summary = table(area,country,region,deathsMedian,deathsLower,deathsUpper,mmrMedian,mmrLower,mmrUpper,deathsLower>0,mmrLower>0,'VariableNames',{'area','country','region','deaths_total_median_rounded','deaths_total_lower_rounded','deaths_total_upper_rounded','mmr_total_median_rounded','mmr_total_lower_rounded','mmr_total_upper_rounded','deaths_detectable','mmr_detectable'});
end

function write_high_burden_table(T,countries,csvFile,texFile)
years = 2020:2023;
out = table(countries(:),'VariableNames',{'Country'});
for y = years
    values = strings(numel(countries),1);
    for i = 1:numel(countries)
        row = T(string(T.country)==countries(i) & T.year==y,:);
        values(i) = triplet(row.excess_median,row.excess_lower,row.excess_upper);
    end
    out.(sprintf('Y%d',y)) = values;
end
total = strings(numel(countries),1);
for i = 1:numel(countries)
    rows = T(string(T.country)==countries(i) & T.year>=2020,:);
    total(i) = triplet(sum(rows.excess_median),sum(rows.excess_lower),sum(rows.excess_upper));
end
out.Total = total;
out.Properties.VariableNames = {'Country','Y2020','Y2021','Y2022','Y2023','Total'};
writetable(out,csvFile);
fid = fopen(texFile,'w');
fprintf(fid,'\\begin{tabular}{lccccc}\n\\toprule\nCountry & 2020 & 2021 & 2022 & 2023 & Total \\\\ \n\\midrule\n');
for i = 1:height(out)
    fprintf(fid,'%s & %s & %s & %s & %s & %s \\\\ \n',escape_tex(out.Country(i)),out.Y2020(i),out.Y2021(i),out.Y2022(i),out.Y2023(i),out.Total(i));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n');
fclose(fid);
end

function write_region_table(summary,csvFile,texFile)
regionOrder = ["African Region","Region of the Americas","Eastern Mediterranean","European Region","Southeast Asia Region","Western Pacific Region"];
display = ["African Region","Region of the Americas","Eastern Mediterranean Region","European Region","South-East Asia Region","Western Pacific Region"];
rows = strings(7,1);
nCountries = zeros(7,1);
deathsText = strings(7,1);
mmrText = strings(7,1);
detectDeaths = zeros(7,1);
detectMmr = zeros(7,1);
rows(1) = "Global";
nCountries(1) = height(summary);
deathsText(1) = triplet(sum(summary.deaths_total_median_rounded),sum(summary.deaths_total_lower_rounded),sum(summary.deaths_total_upper_rounded));
mmrText(1) = triplet(sum(summary.mmr_total_median_rounded),sum(summary.mmr_total_lower_rounded),sum(summary.mmr_total_upper_rounded));
detectDeaths(1) = sum(summary.deaths_detectable);
detectMmr(1) = sum(summary.mmr_detectable);
for i = 1:numel(regionOrder)
    subset = summary(summary.region==regionOrder(i),:);
    rows(i+1) = display(i);
    nCountries(i+1) = height(subset);
    deathsText(i+1) = triplet(sum(subset.deaths_total_median_rounded),sum(subset.deaths_total_lower_rounded),sum(subset.deaths_total_upper_rounded));
    mmrText(i+1) = triplet(sum(subset.mmr_total_median_rounded),sum(subset.mmr_total_lower_rounded),sum(subset.mmr_total_upper_rounded));
    detectDeaths(i+1) = sum(subset.deaths_detectable);
    detectMmr(i+1) = sum(subset.mmr_detectable);
end
out = table(rows,nCountries,deathsText,mmrText,detectDeaths,detectMmr,'VariableNames',{'Region','CountriesIncluded','CumulativeExcessMaternalDeaths','AggregateExcessMMR','CountriesWithExcessDeaths','CountriesWithExcessMMR'});
writetable(out,csvFile);
fid = fopen(texFile,'w');
fprintf(fid,'\\begin{tabular}{lccccc}\n\\toprule\nRegion & Countries & Excess maternal deaths & Excess MMR & Deaths & MMR \\\\ \n\\midrule\n');
for i = 1:height(out)
    fprintf(fid,'%s & %d & %s & %s & %d & %d \\\\ \n',escape_tex(out.Region(i)),out.CountriesIncluded(i),out.CumulativeExcessMaternalDeaths(i),out.AggregateExcessMMR(i),out.CountriesWithExcessDeaths(i),out.CountriesWithExcessMMR(i));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n');
fclose(fid);
end

function plot_forecast_panels(T,countries,yLabel,outputFile)
nCols = 4;
nRows = ceil(numel(countries)/nCols);
fig = figure('Visible','off','Color','w','Units','pixels','Position',[50 50 1300 max(420,260*nRows)]);
layout = tiledlayout(fig,nRows,nCols,'TileSpacing','compact','Padding','compact');
for i = 1:numel(countries)
    ax = nexttile(layout);
    rows = T(string(T.country)==countries(i),:);
    rows = sortrows(rows,'year');
    plot(ax,rows.year,rows.expected_median,'r-','LineWidth',1.2); hold(ax,'on');
    plot(ax,rows.year,rows.expected_lower,'k--','LineWidth',0.8);
    plot(ax,rows.year,rows.expected_upper,'k--','LineWidth',0.8);
    pre = rows.year<=2019;
    post = rows.year>=2020;
    plot(ax,rows.year(pre),rows.observed(pre),'o','MarkerSize',3.5,'MarkerFaceColor','w','MarkerEdgeColor','k','LineStyle','none');
    plot(ax,rows.year(post),rows.observed(post),'o','MarkerSize',4,'MarkerFaceColor',[0 0.55 0],'MarkerEdgeColor',[0 0.55 0],'LineStyle','none');
    yl = ylim(ax);
    patch(ax,[2020 2023.5 2023.5 2020],[yl(1) yl(1) yl(2) yl(2)],[0.9 0.9 0.9],'EdgeColor','none','FaceAlpha',0.55);
    xline(ax,2019,'--','Color',[0.45 0.45 0.45],'LineWidth',0.8);
    h = findobj(ax,'Type','line');
    uistack(h,'top');
    title(ax,countries(i),'Interpreter','none','FontSize',8);
    xlim(ax,[2000 2023]);
    if ceil(i/nCols)==nRows
        xticks(ax,[2000 2011 2023]);
    else
        xticks(ax,[]);
    end
    if mod(i-1,nCols)==0
        ylabel(ax,yLabel,'FontSize',8);
    end
    ax.FontSize = 7;
    ax.Box = 'off';
end
for i = numel(countries)+1:nRows*nCols
    ax = nexttile(layout);
    axis(ax,'off');
end
exportgraphics(fig,outputFile,'ContentType','vector');
close(fig);
end

function plot_excess_bar(T,countries,period,xLabel,outputFile)
values = table;
if ischar(period) || isstring(period)
    for i = 1:numel(countries)
        rows = T(string(T.country)==countries(i) & T.year>=2020,:);
        values = [values; table(countries(i),sum(rows.excess_median),sum(rows.excess_lower),sum(rows.excess_upper),'VariableNames',{'country','median','lower','upper'})];
    end
else
    for i = 1:numel(countries)
        row = T(string(T.country)==countries(i) & T.year==period,:);
        values = [values; table(countries(i),row.excess_median,row.excess_lower,row.excess_upper,'VariableNames',{'country','median','lower','upper'})];
    end
end
values = sortrows(values,{'median','country'},{'descend','ascend'});
n = height(values);
fig = figure('Visible','off','Color','w','Units','pixels','Position',[50 50 900 min(2200,max(500,32*n+160))]);
ax = axes(fig);
y = 1:n;
barh(ax,y,values.median,0.72,'FaceColor',[0.31 0.65 0.82],'EdgeColor','k','LineWidth',0.5); hold(ax,'on');
maxUpper = max(values.upper);
if maxUpper<=0; maxUpper=1; end
pad = max(0.6,0.012*maxUpper);
for i = 1:n
    line(ax,[values.lower(i) values.upper(i)],[y(i) y(i)],'Color','k','LineWidth',1.1);
    line(ax,[values.lower(i) values.lower(i)],[y(i)-0.12 y(i)+0.12],'Color','k','LineWidth',1.1);
    line(ax,[values.upper(i) values.upper(i)],[y(i)-0.12 y(i)+0.12],'Color','k','LineWidth',1.1);
    text(ax,values.upper(i)+pad,y(i),sprintf('%d [%d-%d]',round(values.median(i)),round(values.lower(i)),round(values.upper(i))),'FontSize',7,'VerticalAlignment','middle');
end
ax.YTick = y;
ax.YTickLabel = values.country;
ax.YDir = 'reverse';
ax.TickLabelInterpreter = 'none';
ax.FontSize = 8;
ax.Box = 'off';
ax.XLim = [0 max(1,maxUpper*1.28+pad)];
xlabel(ax,xLabel,'FontSize',10);
exportgraphics(fig,outputFile,'ContentType','vector');
close(fig);
end

function s = triplet(m,l,u)
s = string(sprintf('%d (%d, %d)',round(max(0,m)),round(max(0,l)),round(max(0,u))));
end

function s = escape_tex(value)
s = char(string(value));
s = strrep(s,'&','\\&');
s = strrep(s,'_','\\_');
end
