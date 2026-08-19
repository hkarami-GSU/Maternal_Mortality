function collect_forecasts(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
classification = readtable(fullfile(projectRoot,'data','source','mmeig','Classification.xlsx'),'VariableNamingRule','preserve');
classification = sortrows(classification,'Number');
assert(height(classification)==195,'Classification file must contain 195 rows.');
outputDir = fullfile(projectRoot,'outputs','model_results');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
runDir = fullfile(projectRoot,'code','subepidemic','toolbox','output');
configs = {
    'mmr','yearly-mmr-deaths-world','transformed_ratio_data.csv';
    'maternal_deaths','yearly-maternal-deaths-world','transformed_maternal_deaths_data.csv'
};
selectionAll = table;
for c = 1:size(configs,1)
    outcome = string(configs{c,1});
    stem = string(configs{c,2});
    observedFile = fullfile(projectRoot,'data','processed','model_inputs',configs{c,3});
    observedTable = readtable(observedFile,'VariableNamingRule','preserve');
    years = observedTable.Year;
    assert(isequal(years(:),(2000:2023)'),'Observed input must contain 2000 through 2023.');
    nRows = 195*numel(years);
    outcomeCol = strings(nRows,1);
    areaCol = zeros(nRows,1);
    countryCol = strings(nRows,1);
    sourceCountryCol = strings(nRows,1);
    regionCol = strings(nRows,1);
    yearCol = zeros(nRows,1);
    observedCol = zeros(nRows,1);
    medianCol = zeros(nRows,1);
    lowerCol = zeros(nRows,1);
    upperCol = zeros(nRows,1);
    modelSourceCol = strings(nRows,1);
    excessMedian = nan(nRows,1);
    excessLower = nan(nRows,1);
    excessUpper = nan(nRows,1);
    signedDeviation = nan(nRows,1);
    ratio = nan(nRows,1);
    logRatio = nan(nRows,1);
    selectionOutcome = strings(195,1);
    selectionArea = (1:195)';
    selectionCountry = strings(195,1);
    selectionRegion = strings(195,1);
    selectionSourceCountry = strings(195,1);
    selectionModelSource = strings(195,1);
    selectionModelFile = strings(195,1);
    selectionCoverage = zeros(195,1);
    selectionMeanWidth = zeros(195,1);
    rowIndex = 0;
    for area = 1:195
        country = string(classification.Country(area));
        region = string(classification.Region(area));
        sourceCountry = string(observedTable.Properties.VariableNames{area+1});
        observedValues = observedTable{:,area+1};
        [modelFile,modelSource,coverage,meanWidth] = select_model_file(runDir,stem,area);
        M = readtable(modelFile,'VariableNamingRule','preserve');
        assert(height(M)==24,'Selected forecast must contain 24 rows: %s',modelFile);
        selectionOutcome(area) = outcome;
        selectionCountry(area) = country;
        selectionRegion(area) = region;
        selectionSourceCountry(area) = sourceCountry;
        selectionModelSource(area) = modelSource;
        [~,name,ext] = fileparts(modelFile);
        selectionModelFile(area) = string([name ext]);
        selectionCoverage(area) = coverage;
        selectionMeanWidth(area) = meanWidth;
        for j = 1:numel(years)
            rowIndex = rowIndex + 1;
            y = years(j);
            o = observedValues(j);
            e = M.median(j);
            l = M.LB(j);
            u = M.UB(j);
            outcomeCol(rowIndex) = outcome;
            areaCol(rowIndex) = area;
            countryCol(rowIndex) = country;
            sourceCountryCol(rowIndex) = sourceCountry;
            regionCol(rowIndex) = region;
            yearCol(rowIndex) = y;
            observedCol(rowIndex) = o;
            medianCol(rowIndex) = e;
            lowerCol(rowIndex) = l;
            upperCol(rowIndex) = u;
            modelSourceCol(rowIndex) = modelSource;
            if y >= 2020
                excessMedian(rowIndex) = max(0,o-e);
                excessLower(rowIndex) = max(0,o-u);
                excessUpper(rowIndex) = max(0,o-l);
                signedDeviation(rowIndex) = o-e;
                if e > 0
                    ratio(rowIndex) = o/e;
                    if ratio(rowIndex) > 0
                        logRatio(rowIndex) = log(ratio(rowIndex));
                    end
                end
            end
        end
    end
    forecast = table(outcomeCol,areaCol,countryCol,sourceCountryCol,regionCol,yearCol,observedCol,medianCol,lowerCol,upperCol,modelSourceCol,excessMedian,excessLower,excessUpper,signedDeviation,ratio,logRatio,'VariableNames',{'outcome','area','country','source_country_name','region','year','observed','expected_median','expected_lower','expected_upper','model_source','excess_median','excess_lower','excess_upper','signed_deviation','observed_expected_ratio','log_observed_expected_ratio'});
    excess = forecast(forecast.year>=2020,:);
    writetable(forecast,fullfile(outputDir,sprintf('forecast_%s_country_year.csv',outcome)));
    writetable(excess,fullfile(outputDir,sprintf('excess_%s_country_year.csv',outcome)));
    selection = table(selectionOutcome,selectionArea,selectionCountry,selectionRegion,selectionSourceCountry,selectionModelSource,selectionModelFile,selectionCoverage,selectionMeanWidth,'VariableNames',{'outcome','area','country','region','source_country_name','model_source','source_model_file','calibration_coverage','mean_interval_width'});
    selectionAll = [selectionAll; selection];
end
writetable(selectionAll,fullfile(outputDir,'model_selection.csv'));
fprintf('Compact forecast files written to %s\n',outputDir);
end

function [selectedFile,sourceType,coverage,meanWidth] = select_model_file(runDir,stem,area)
pattern = sprintf('*%s-area-%d-01-01-2019.csv',stem,area);
files = dir(fullfile(runDir,pattern));
keep = startsWith({files.name},'Ensemble(4)') | startsWith({files.name},'ranked(1)');
files = files(keep);
assert(~isempty(files),'No forecast file found for %s area %d.',stem,area);
n = numel(files);
coverageValues = zeros(n,1);
widthValues = zeros(n,1);
priority = zeros(n,1);
distPriority = zeros(n,1);
for i = 1:n
    filePath = fullfile(files(i).folder,files(i).name);
    T = readtable(filePath,'VariableNamingRule','preserve');
    assert(all(ismember({'data','median','LB','UB'},T.Properties.VariableNames)),'Forecast file is missing required columns: %s',filePath);
    calibration = 1:min(20,height(T));
    coverageValues(i) = sum(T.data(calibration)>=T.LB(calibration) & T.data(calibration)<=T.UB(calibration));
    widthValues(i) = mean(T.UB(calibration)-T.LB(calibration),'omitnan');
    priority(i) = ~startsWith(files(i).name,'Ensemble(4)');
    token = regexp(files(i).name,'-dist-(\d+)-','tokens','once');
    if isempty(token)
        distPriority(i) = 9;
    else
        distPriority(i) = str2double(token{1});
    end
end
S = table(-coverageValues,widthValues,priority,distPriority,(1:n)','VariableNames',{'negativeCoverage','meanWidth','priority','dist','index'});
S = sortrows(S,{'negativeCoverage','meanWidth','priority','dist'});
best = S.index(1);
selectedFile = fullfile(files(best).folder,files(best).name);
if startsWith(files(best).name,'Ensemble(4)')
    sourceType = "ensemble_top4";
else
    sourceType = "ranked_top1";
end
coverage = coverageValues(best);
meanWidth = widthValues(best);
end
