clc; clear; close all;

output_folder = 'output';
output_filename_suffix = '_maternaldeaths.pdf';
calibration_period = 20;
numCols = 4;
titleFontSize = 19.5;
labelFontSize = 19.5;
tickFontSize = 22;
legendFontSize = 18;
markerSize = 12;
lineWidth = 2.5;
dashedLineWidth = 1.7;
gridAlpha = 0.3;
widthPerCol = 4.5;
heightPerRow = 3.5;

results = zeros(195,1);
for area = 1:195, results(area) = 0; end

try
    classificationData = readtable('Classification.xlsx','Sheet',1);
catch ME
    error('Could not read Classification.xlsx: %s',ME.message);
end

regions = {"Eastern Mediterranean","European Region","African Region",...
           "Western Pacific Region","Region of the Americas","Southeast Asia Region",...
           "Global","High Burden Countries"};

disp("Select a region from the following list:")
for i = 1:length(regions), fprintf("%d: %s\n", i, regions{i}); end

while true
    selectedIndex = input("Enter the number corresponding to your chosen region: ");
    if isnumeric(selectedIndex)&&selectedIndex>=1&&selectedIndex<=length(regions), break; end
    fprintf("Invalid selection. Please enter a number between 1 and %d.\n",length(regions));
end

selectedRegion = regions{selectedIndex};

if selectedIndex==8
    highBurdenCountries = {'Afghanistan','South Sudan','Chad','Nigeria','Guinea-Bissau','Liberia','Somalia','Lesotho'};
    filteredData = classificationData(ismember(classificationData{:,2},highBurdenCountries),:);
else
    filteredData = classificationData(strcmp(classificationData{:,3},selectedRegion),:);
end

selectedAreas = filteredData{:,1};
selectedCountries = filteredData{:,2};

save('selected_region_data.mat','selectedRegion','selectedAreas','selectedCountries');
save('best_methods.mat','results');

if ~exist(output_folder,'dir')
    warning('Output folder "%s" does not exist. Please check the path.',output_folder);
    return;
end

try
    mmr_data = readmatrix('transformed_maternal_deaths_data.xlsx');
catch ME
    error('Could not read transformed_ratio_data.xlsx: %s',ME.message);
end

numAreas = length(selectedAreas);
existingFiles = false(1,numAreas);
existingFilenames = cell(1,numAreas);
fileTypes = cell(1,numAreas);

fprintf('Checking for CSV files in %s folder...\n',output_folder);

for i=1:numAreas
    area=selectedAreas(i);
    dist=results(area);
    ensembleFilename=sprintf('%s/Ensemble(4)-onsetfixed-0-flag1-1-method-0-dist-%d-horizon-4-weighttype-0-yearly-maternal-deaths-world-area-%d-01-01-2019.csv',output_folder,dist,area);
    rankedFilename=sprintf('%s/ranked(1)-onsetfixed-0-flag1-1-method-0-dist-0-horizon-4-yearly-maternal-deaths-world-area-%d-01-01-2019.csv',output_folder,area);
    
    if exist(ensembleFilename,'file')
        existingFiles(i)=true;
        existingFilenames{i}=ensembleFilename;
        fileTypes{i}='ensemble';
        fprintf(' ✓ Found Ensemble: %s\n',ensembleFilename);
    elseif exist(rankedFilename,'file')
        existingFiles(i)=true;
        existingFilenames{i}=rankedFilename;
        fileTypes{i}='ranked';
        fprintf(' ✓ Found Ranked(1): %s\n',rankedFilename);
    else
        existingFiles(i)=false;
        existingFilenames{i}='';
        fileTypes{i}='';
        fprintf(' ✗ Missing both Ensemble and Ranked: area %d\n',area);
    end
end

actualNumPlots=sum(existingFiles);
actualNumRows=ceil(actualNumPlots/numCols);

if actualNumPlots==0
    error('No CSV files found in the %s folder. Please check file paths and names.',output_folder);
end

fprintf('\nFound %d out of %d expected files.\n',actualNumPlots,numAreas);

figureWidthPixels = numCols * widthPerCol * 96;
figureHeightPixels = actualNumRows * heightPerRow * 96;
figure('Position',[100,100,figureWidthPixels,figureHeightPixels]);
subplot_counter=0;
years=(2000:2023)';

for i=1:numAreas
    area=selectedAreas(i);
    csvFilename=existingFilenames{i};
    fileType=fileTypes{i};
    
    if ~existingFiles(i), continue; end
    
    subplot_counter=subplot_counter+1;
    
    try
        data=readmatrix(csvFilename);
        
        if strcmp(fileType,'ensemble')
            actual_data=data(:,4);
            median_data=data(:,5);
            lower_bounds_all=data(:,6);
            upper_bounds_all=data(:,7);
        else
            actual_data=data(:,2);
            median_data=data(:,3);
            lower_bounds_all=data(:,4);
            upper_bounds_all=data(:,5);
        end
        
        if size(data,1)~=length(years), continue; end
        
        excel_start_year=1985;
        forecast_years_needed=[2020,2021,2022,2023];
        forecast_indices=forecast_years_needed-excel_start_year+1;
        
        if area<=size(mmr_data,2) && size(mmr_data,1)>=max(forecast_indices)
            mmr_forecast_data=mmr_data(forecast_indices,area+1);
        else
            continue;
        end
        
        forecast_start_idx=calibration_period+1;
        forecast_years=years(forecast_start_idx:end);
        lower_bounds=lower_bounds_all(forecast_start_idx:end);
        below_lb_idx_forecast=mmr_forecast_data<lower_bounds;
        
        subplot(actualNumRows,numCols,subplot_counter);
        hold on;
        
        plot(years(1:calibration_period),actual_data(1:calibration_period),'o',...
            'MarkerEdgeColor','k','MarkerFaceColor','none','MarkerSize',markerSize);
        plot(years(forecast_start_idx:end),mmr_forecast_data,'o',...
            'MarkerEdgeColor',[0 0.5 0],'MarkerFaceColor',[0 0.5 0],'MarkerSize',markerSize);
        plot(years,median_data,'r-','LineWidth',lineWidth);
        plot(years,lower_bounds_all,'k--','LineWidth',dashedLineWidth);
        plot(years,upper_bounds_all,'k--','LineWidth',dashedLineWidth);
        
        xlim([2000,2023]);
        ylims=ylim;
        ylower = max(0, min(ylims)-1);
        yupper = max(ylims)+1;
        ylim([ylower, yupper]);
        ylims=ylim;
        
        set(gca,'Clipping','off');
        patch([2019,2023,2023,2019],[ylims(1),ylims(1),ylims(2),ylims(2)],...
            [0.7,0.7,0.7],'FaceAlpha',gridAlpha,'EdgeColor','none','Clipping','off');
        uistack(findobj(gca,'Type','patch'),'bottom');
        
        xline(2019,'b--','LineWidth',dashedLineWidth);
        
        title(sprintf('%s',selectedCountries{i}),'Interpreter','latex','FontSize',titleFontSize);
        
        ytick_vals=[ylims(1),mean(ylims),ylims(2)];
        yticks(ytick_vals);
        yticklabels(string(floor(ytick_vals)));
        
        if subplot_counter>(actualNumPlots-numCols)
            xticks([2000,2011,2023]); 
        else
            xticks([]);
        end

        
        if mod(subplot_counter-1,numCols)==0
            ylabel('Maternal Deaths','Interpreter','latex','FontSize',labelFontSize);
        end
        
        set(gca,'FontSize',tickFontSize,'TickLabelInterpreter','latex');
        
        grid on;
        set(gca,'Layer','top');
        
        hold off;
    catch
        continue;
    end
end

if actualNumPlots>0
    totalWidth=numCols*widthPerCol;
    totalHeight=actualNumRows*heightPerRow;
    
    fig=gcf;
    fig.PaperUnits='inches';
    fig.PaperPosition=[0,0,totalWidth,totalHeight];
    fig.PaperSize=[fig.PaperPosition(3),fig.PaperPosition(4)];
    
    output_filename = sprintf('%s%s', selectedRegion, output_filename_suffix);
    output_filename = strrep(output_filename, ' ', '_');
    
    print(fig,output_filename,'-dpdf','-r300');
    fprintf('\nFigure saved as: %s\n',output_filename);
else
    fprintf('\nNo plots were created due to missing data files.\n');
end

fprintf('\nProcessing complete!\n');