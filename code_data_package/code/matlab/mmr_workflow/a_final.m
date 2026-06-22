clc; clear; close all;
output_folder='output'; figures_folder='excess_deaths_figures'; calibration_period=20; results=zeros(195,1); for area=1:195, results(area)=0; end
if ~exist(figures_folder,'dir'), mkdir(figures_folder); fprintf('Created output folder: %s\n',figures_folder); end
years=(2000:2023)'; years_to_plot=2020:2023;
try, classificationData=readtable('Classification.xlsx','Sheet',1); catch ME, error('Could not read Classification.xlsx: %s',ME.message); end
regions={"Eastern Mediterranean","European Region","African Region","Western Pacific Region","Region of the Americas","Southeast Asia Region","Global","High Burden Countries"};
disp("Select a region from the following list:"); for i=1:length(regions), fprintf("%d: %s\n",i,regions{i}); end
while true, selectedIndex=input("Enter the number corresponding to your chosen region: "); if isnumeric(selectedIndex)&&selectedIndex>=1&&selectedIndex<=length(regions), break; end, fprintf("Invalid selection. Please enter a number between 1 and %d.\n",length(regions)); end
selectedRegion=regions{selectedIndex};
if selectedIndex==8, highBurdenCountries={'Bangladesh','China','India','Indonesia','Nigeria','DRC','Philippines','Pakistan'}; filteredData=classificationData(ismember(classificationData{:,2},highBurdenCountries),:);
else, filteredData=classificationData(strcmp(classificationData{:,3},selectedRegion),:); end
selectedAreas=filteredData{:,1}; selectedCountries=filteredData{:,2};
save('selected_region_data.mat','selectedRegion','selectedAreas','selectedCountries'); save('best_methods.mat','results');
if ~exist(output_folder,'dir'), warning('Output folder "%s" does not exist. Please check the path.',output_folder); return; end
try, mmr_data=readmatrix('transformed_ratio_data.xlsx'); catch ME, error('Could not read transformed_ratio_data.xlsx: %s',ME.message); end
numAreas=length(selectedAreas); existingFiles=false(1,numAreas); existingFilenames=cell(1,numAreas); fileTypes=cell(1,numAreas);
fprintf('Checking for CSV files in %s folder...\n',output_folder);
for i=1:numAreas, area=selectedAreas(i); dist=results(area); ensembleFilename=sprintf('%s/Ensemble(4)-onsetfixed-0-flag1-1-method-0-dist-%d-horizon-4-weighttype-0-yearly-mmr-deaths-world-area-%d-01-01-2019.csv',output_folder,dist,area); rankedFilename=sprintf('%s/ranked(1)-onsetfixed-0-flag1-1-method-0-dist-0-horizon-4-yearly-mmr-deaths-world-area-%d-01-01-2019.csv',output_folder,area);
    if exist(ensembleFilename,'file'), existingFiles(i)=true; existingFilenames{i}=ensembleFilename; fileTypes{i}='ensemble'; fprintf(' ✓ Found Ensemble: %s\n',ensembleFilename);
    elseif exist(rankedFilename,'file'), existingFiles(i)=true; existingFilenames{i}=rankedFilename; fileTypes{i}='ranked'; fprintf(' ✓ Found Ranked(1): %s\n',rankedFilename);
    else, existingFiles(i)=false; existingFilenames{i}=''; fileTypes{i}=''; fprintf(' ✗ Missing both Ensemble and Ranked: area %d\n',area); end
end
actualNumFiles=sum(existingFiles); if actualNumFiles==0, error('No CSV files found in the %s folder. Please check file paths and names.',output_folder); end
fprintf('\nFound %d out of %d expected files.\n',actualNumFiles,numAreas);
excessDeaths=cell(numAreas,length(years_to_plot)+2); excel_start_year=1985; forecast_years_needed=years_to_plot; forecast_indices=forecast_years_needed-excel_start_year+1;
for i=1:numAreas
    if ~existingFiles(i), continue; end
    area=selectedAreas(i); csvFilename=existingFilenames{i}; fileType=fileTypes{i};
    try, data=readmatrix(csvFilename);
        if strcmp(fileType,'ensemble'), median_data=data(:,5); lower_bounds_all=data(:,6); upper_bounds_all=data(:,7);
        else, median_data=data(:,3); lower_bounds_all=data(:,4); upper_bounds_all=data(:,5); end
        if size(data,1)~=length(years), continue; end
        if area<=size(mmr_data,2)&&size(mmr_data,1)>=max(forecast_indices), mmr_forecast_data=mmr_data(forecast_indices,area+1); else, continue; end
        total_excess_median=0; total_excess_lower=0; total_excess_upper=0;
        for j=1:length(years_to_plot), current_year=years_to_plot(j); year_idx=find(years==current_year);
            if ~isempty(year_idx), excel_value=mmr_forecast_data(j);
                current_excess_median=max(0,excel_value-median_data(year_idx)); current_excess_lower=max(0,excel_value-upper_bounds_all(year_idx)); current_excess_upper=max(0,excel_value-lower_bounds_all(year_idx));
                total_excess_median=total_excess_median+current_excess_median; total_excess_lower=total_excess_lower+current_excess_lower; total_excess_upper=total_excess_upper+current_excess_upper;
                excessDeaths{i,j+1}=[current_excess_median,current_excess_lower,current_excess_upper];
            end
        end
        excessDeaths{i,1}=selectedCountries{i}; excessDeaths{i,length(years_to_plot)+2}=[total_excess_median,total_excess_lower,total_excess_upper];
    catch, continue; end
end
country_spacing_factor=0.4;
for year_idx=1:length(years_to_plot), current_year=years_to_plot(year_idx); valid_indices=~cellfun(@isempty,excessDeaths(:,year_idx+1)); valid_countries=excessDeaths(valid_indices,1);
    if isempty(valid_countries), continue; end
    year_medians=zeros(length(valid_countries),1); year_lowers=zeros(length(valid_countries),1); year_uppers=zeros(length(valid_countries),1);
    for i=1:length(valid_countries), valid_idx=find(valid_indices); data_values=excessDeaths{valid_idx(i),year_idx+1}; year_medians(i)=data_values(1); year_lowers(i)=data_values(2); year_uppers(i)=data_values(3); end
    sort_matrix=[year_medians,year_uppers,year_lowers]; [~,sort_idx]=sortrows(sort_matrix,[1,2,3],{'ascend','ascend','ascend'});
    sorted_countries=valid_countries(sort_idx); sorted_medians=year_medians(sort_idx); sorted_lowers=year_lowers(sort_idx); sorted_uppers=year_uppers(sort_idx);
    baseHeight=20*country_spacing_factor; minHeight=300+(300*country_spacing_factor); height=max(minHeight,baseHeight*length(sorted_countries)); width=800+(400*min(country_spacing_factor,2));
    fig=figure('Position',[100,100,width,height]); y_positions=1:length(sorted_countries);
    barh(y_positions,sorted_medians,'FaceColor',[0.3 0.6 0.8]); hold on;
    err_neg=sorted_medians-sorted_lowers; err_pos=sorted_uppers-sorted_medians; errorbar(sorted_medians,y_positions,err_neg,err_pos,'horizontal','.k','LineWidth',1.5);
    yticks(y_positions); font_size=max(8,12-country_spacing_factor); set(gca,'YTickLabel',sorted_countries,'TickLabelInterpreter','latex','FontSize',font_size);
    xlabel(sprintf('Excess MMR in %d',current_year),'FontSize',12,'FontWeight','bold','Interpreter','latex');
    max_text_width=0; for i=1:length(y_positions), text_str=sprintf('$%d \\, [%d\\mbox{--}%d]$',round(sorted_medians(i)),round(sorted_lowers(i)),round(sorted_uppers(i))); max_text_width=max(max_text_width,length(text_str)*max(sorted_uppers)*0.01); end
    max_data_value=max(sorted_uppers); padding=max_data_value*0.05; text_space=max_text_width*1.2; xlim([0,max_data_value+padding+text_space]);
    for i=1:length(y_positions), text(sorted_uppers(i)+padding,y_positions(i),sprintf('$%d \\, [%d\\mbox{--}%d]$',round(sorted_medians(i)),round(sorted_lowers(i)),round(sorted_uppers(i))),'VerticalAlignment','middle','HorizontalAlignment','left','FontSize',12,'Interpreter','latex'); end
    grid on; set(gca,'YGrid','off'); box off; set(gca,'FontSize',font_size,'LineWidth',1.2);
    left_margin=0.15+(0.1*min(country_spacing_factor,2)); bottom_margin=0.12; set(gca,'Position',[left_margin,bottom_margin,0.95-left_margin-0.05,0.85-bottom_margin]);
    set(fig,'PaperUnits','inches'); set(fig,'PaperOrientation','portrait'); width_inches=8+(4*min(country_spacing_factor,2)); height_inches=height/100; set(fig,'PaperSize',[width_inches height_inches]); set(fig,'PaperPosition',[0 0 width_inches height_inches]);
    exportname=sprintf('%s/ExcessDeaths_%s_%d.pdf',figures_folder,selectedRegion,current_year); print(fig,exportname,'-dpdf','-r600'); fprintf('Saved: %s\n',exportname);
    hold off; close(fig);
end
country_spacing_factor = 0.4;
valid_indices=~cellfun(@isempty,excessDeaths(:,end)); valid_countries=excessDeaths(valid_indices,1);
if ~isempty(valid_countries), total_medians=zeros(length(valid_countries),1); total_lowers=zeros(length(valid_countries),1); total_uppers=zeros(length(valid_countries),1);
for i=1:length(valid_countries), valid_idx=find(valid_indices); data_values=excessDeaths{valid_idx(i),end}; total_medians(i)=data_values(1); total_lowers(i)=data_values(2); total_uppers(i)=data_values(3); end
 sort_matrix=[total_medians,total_uppers,total_lowers]; [~,sort_idx]=sortrows(sort_matrix,[1,2,3],{'ascend','ascend','ascend'});
 sorted_countries=valid_countries(sort_idx); sorted_medians=total_medians(sort_idx); sorted_lowers=total_lowers(sort_idx); sorted_uppers=total_uppers(sort_idx);
 baseHeight=20*country_spacing_factor; minHeight=300+(300*country_spacing_factor); total_height=max(minHeight,baseHeight*length(sorted_countries)); width=800+(400*min(country_spacing_factor,2));
 fig=figure('Position',[100,100,width,total_height]); y_positions=1:length(sorted_countries);
 barh(y_positions,sorted_medians,'FaceColor',[0.3 0.6 0.8]); hold on; err_neg=sorted_medians-sorted_lowers; err_pos=sorted_uppers-sorted_medians; errorbar(sorted_medians,y_positions,err_neg,err_pos,'horizontal','.k','LineWidth',1.5);
 yticks(y_positions); font_size=max(8,12-country_spacing_factor); set(gca,'YTickLabel',sorted_countries,'TickLabelInterpreter','latex','FontSize',font_size);
 xlabel(sprintf('Total Excess MMR (%d-%d)',years_to_plot(1),years_to_plot(end)),'FontSize',12,'FontWeight','bold','Interpreter','latex');
 max_text_width=0; for i=1:length(y_positions), text_str=sprintf('$%d \\, [%d\\mbox{--}%d]$',round(sorted_medians(i)),round(sorted_lowers(i)),round(sorted_uppers(i))); max_text_width=max(max_text_width,length(text_str)*max(sorted_uppers)*0.01); end
 max_data_value=max(sorted_uppers); padding=max_data_value*0.05; text_space=max_text_width*1.2; xlim([0,max_data_value+padding+text_space]);
for i=1:length(y_positions), text(sorted_uppers(i)+padding,y_positions(i),sprintf('$%d \\, [%d\\mbox{--}%d]$',round(sorted_medians(i)),round(sorted_lowers(i)),round(sorted_uppers(i))),'VerticalAlignment','middle','HorizontalAlignment','left','FontSize',12,'Interpreter','latex'); end
 grid on; set(gca,'YGrid','off'); box off; set(gca,'FontSize',font_size,'LineWidth',1.2); set(gca,'Position',[0.2,0.12,0.75,0.83]);
 set(fig,'PaperUnits','inches'); set(fig,'PaperOrientation','portrait'); width_inches=8+(4*min(country_spacing_factor,2)); height_inches=total_height/100;
 set(fig,'PaperSize',[width_inches height_inches]); set(fig,'PaperPosition',[0 0 width_inches height_inches]);
 exportname=sprintf('%s/ExcessDeaths_%s_Total.pdf',figures_folder,selectedRegion); print(fig,exportname,'-dpdf','-r600'); fprintf('Saved: %s\n',exportname); hold off; close(fig);
end
columnNames={'State'}; yearColumns=arrayfun(@(x)sprintf('Excess (LB,UB) %d',x),years_to_plot,'UniformOutput',false); columnNames=[columnNames,yearColumns,{'Excess (LB,UB) Total'}];
formattedData=cell(size(excessDeaths,1),length(columnNames)); formattedData(:,1)=excessDeaths(:,1);
for i=1:size(excessDeaths,1), for j=2:length(columnNames), data_idx=j; if j<=length(columnNames)&&~isempty(excessDeaths{i,data_idx}), formattedData{i,j}=sprintf('%.0f (%.0f, %.0f)',excessDeaths{i,data_idx}(1),excessDeaths{i,data_idx}(2),excessDeaths{i,data_idx}(3)); else, formattedData{i,j}=''; end, end, end
formattedTable=cell2table(formattedData,'VariableNames',columnNames); excel_output=sprintf('%s/ExcessDeaths_%s_Formatted.xlsx',figures_folder,selectedRegion); writetable(formattedTable,excel_output); fprintf('Saved: %s\n',excel_output);
fprintf('\nProcessing complete! All outputs saved in %s folder.\n',figures_folder);
