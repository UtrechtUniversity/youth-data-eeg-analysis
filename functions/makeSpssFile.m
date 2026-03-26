path2BCT = '~/Matlab_Toolboxes/Connectivity/2016_01_16_BCT/';
addpath(path2BCT)

load('results/nanbadchannels_[4-7]_allCorrelationMatrices.mat')

results = [];
for i = 1:length(allSubjectResults.dirNames)
    results(i).subjectname = allSubjectResults.dirNames{i};
    results(i).filename = allSubjectResults.origFilenames{i};
    
    if strcmp(allSubjectResults.condition{i}, 'ASS')
        results(i).condition = 1;
    elseif strcmp(allSubjectResults.condition{i}, 'Controle')
        results(i).condition = 0;
    else
        error('Condition unknown for subject %s', allSubjectResults.dirNames{i})
    end
    
    results(i).meanWPLI = nanmean(nanmean(allSubjectResults.corrMatrices.wpli_debiased(:,:,i)));
    results(i).effWPLI = efficiency_wei(thresWPliCIJ(:,:,i));
    results(i).clustcoeffWeightWPLI = mean(clustering_coef_wu(thresWPliCIJ(:,:,i)));
    currRichClubCurve = rich_club_wu(thresWPliCIJ(:,:,i));
    currRichClubCurve(end:30) = NaN;
    allRichClubCurves(i,:) = currRichClubCurve;
end

allRichClubCurves(isnan(allRichClubCurves)) = 0;

