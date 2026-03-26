function corrMatrices = compareAnalysisMethods(cfg)

analysisMethods = ft_getopt(cfg, 'analysisMethods');
freqband        = ft_getopt(cfg, 'freqband');

setStandards();
corrMatrices = [];
corrMatrices.mat1 = [];
corrMatrices.mat2 = [];
corrMatrices.twodim1 = [];
corrMatrices.twodim2 = [];
corrMatrices.allAnalyses1 = strsplit(analysisMethods{1},'_');
corrMatrices.allAnalyses2 = strsplit(analysisMethods{2},'_');

diffLogicals = ~strcmp(corrMatrices.allAnalyses1, corrMatrices.allAnalyses2);

for i = 1:length(analysisMethods)
    cd([PATHS.RESULTS filesep analysisMethods{i}])
    
    corrMats = dir(['*_[' strrep(num2str(freqband), '  ', '-') ']' ...
        '_allCorrelationMatrices.mat']);
    
    try
        load(corrMats.name)
    catch
        error('allCorrelationMatrices not found for method: %s', ...
            analysisMethods{i})
    end
    
    matVarName = ['mat' num2str(i)];
    twodimVarName = ['twodim' num2str(i)];
    analysisVarName = ['allAnalyses' num2str(i)];
    
    corrMatrices.(matVarName) = allSubjectResults.corrMatrices;
    corrMatrices.(twodimVarName) = ...
        reshape(allSubjectResults.corrMatrices, ...
        [1, size(allSubjectResults.corrMatrices, 2) * ...
            size(allSubjectResults.corrMatrices, 2) * ...
            size(allSubjectResults.corrMatrices, 3)]);
    
    figure(i)
    imagesc(nanmean(corrMatrices.(matVarName),3))
    colorbar()
    
    analysisName{i} = [corrMatrices.(analysisVarName){diffLogicals}];
    title(analysisName{i})
end

validdata(:,1) = corrMatrices.twodim1;
validdata(:,2) = corrMatrices.twodim2;

isNan = isnan(validdata(:,1)) | isnan(validdata(:,2)) ;
validdata(isNan, :) = [];

pfit = polyfit(validdata(:,1),validdata(:,2),1);
lin1 = polyval(pfit, validdata(:,1));
R = corrcoef(validdata(:,1),validdata(:,2));

fig3 = figure; 
scatter(validdata(:,1), validdata(:,2));
hold on
plot(validdata(:,1),lin1)
xlabel(analysisName{1})
ylabel(analysisName{2})
axis([-0.5 1 -0.5 1])
title(['R^2 = ' num2str(R(2)^2)])

cd(PATHS.FIGURES)
filenameFig1 = [analysisName{1} '_corrMatrices'];
print(figure(1), filenameFig1, '-dpng')

filenameFig2 = [analysisName{2} '_corrMatrices'];
print(figure(2), filenameFig2, '-dpng')

filenameFig3 = [analysisName{1} 'vs' analysisName{2} '_scatterplot'];
print(fig3, filenameFig3, '-dpng')

cd(PATHS.ROOT)
close all;