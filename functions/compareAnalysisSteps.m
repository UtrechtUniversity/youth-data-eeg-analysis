function compareAnalysisSteps(cfg)

comparedAnalysis 	= ft_getopt(cfg, 'comparedAnalysis');
freqrange 			= ft_getopt(cfg, 'freqrange');

setStandards();

standardString = 'Cutdata_filter[1-Inf]+rerefnoBadChannels_trialfungeneral_kurt10_*_invVar0.03_10s_wplidebiased_withBadChannels';
standardStr = strsplit(standardString, '_');

cutDataInd              = 1;
preprocessFilterInd 	= 2;
trialfunInd 			= 3;
kurtInd 				= 4;
varianceInd 			= 5;
invVarInd 				= 6;
triallengthInd          = 7;
corrMethodInd			= 8;
badChannelsInd          = 9;

eval(['a = ' comparedAnalysis 'Ind;']);
standardStr{a} = '*'; 
standardString = strjoin(standardStr, '_');

cd(PATHS.RESULTS)

allResultsFolders = dir(standardString);
allResultsFolderNames = {allResultsFolders.name};
amountOfFoldersUsed = 0;

for iDir = 1:length(allResultsFolders)
    currFolder = allResultsFolders(iDir).name;
    allCurrAnalysis = strsplit(currFolder, '_');
    currVar = allCurrAnalysis{a};
    
    cd(currFolder) 
    
    try
        load('allFreqsData_[1-100].mat')
    catch
        cd(PATHS.RESULTS)
        err = lasterror;
        warning('%s: \n \t %s',currFolder,err.message)
        continue
    end
    
    amountOfFoldersUsed = amountOfFoldersUsed + 1;
    allVars(amountOfFoldersUsed) = str2double(regexprep(currVar,'\D',''));
    allVarLabels{amountOfFoldersUsed} = currVar;
    
    freqDiff = diff([1 100]);
    step = freqDiff/(size(allFreqsData,3)-1);
    
    freqVector = 1:step:100;
    
    ind1 = find(freqVector == freqrange(1));
    ind2 = find(freqVector == freqrange(2));
    
    currPLIMean = squeeze(nanmean(nanmean(nanmean(allFreqsData(:,:,ind1:ind2,:),1),2),3));
    avgPLIAllSubjects(amountOfFoldersUsed) = nanmean(currPLIMean);
    currStd = nanstd(currPLIMean);
    sePLIAllSubjects(amountOfFoldersUsed) = currStd / sqrt(numel(currPLIMean));
    
%     cd(PATHS.ROOT)
%     cfg = [];
%     cfg.freqband            = freqrange;
%     cfg.analysisMethods     = ...
%         {standardString, currFolder};
%     compareAnalysisMethods(cfg);
    
    cd(PATHS.RESULTS)
end
[~, sortIdx] = sort(allVars);

avgPLIAllSubjects = avgPLIAllSubjects(sortIdx);
allVarLabels = allVarLabels(sortIdx);
allVars = allVars(sortIdx);

cd(PATHS.FIGURES)
fig1 = figure;
plot(allVars, avgPLIAllSubjects, 'bo-')
errorbar(allVars,avgPLIAllSubjects, sePLIAllSubjects,'o')
ylabel('Mean Correlation Value')
titleStr = ['mean correlation value for different ' comparedAnalysis];
title(titleStr)
barfigName = [comparedAnalysis '_barplot'];
print(fig1, barfigName, '-deps')

cd(PATHS.ROOT)