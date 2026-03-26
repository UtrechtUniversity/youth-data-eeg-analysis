function visualizeCorrMatrices(cfg)
% cuts data (if needed) into trials and automatically removes trials based
% on given extreme values
%
% usage  visualizeCorrMatrices(cfg)
%
% with config file with variables:
%   cfg.analysisTree:       [string] created in
%                               completeAnalysisBabyConnectivity.m
%   cfg.freqband:           [string] frequency band to be visualized

% read out options from configuration file
analysisTree    = ft_getopt(cfg, 'analysisTree');
freqband        = ft_getopt(cfg, 'freqband');

% Set standards and options
setStandards()

cd([PATHS.RESULTS filesep analysisTree])
corrMats = dir(['*_[' strrep(num2str(freqband), '  ', '-') ']' '_allCorrelationMatrices.mat']);
try
    load(corrMats.name)
catch
    error('all correlation matrices file not found')
end

% Plot a figure of all the correlation matrices for all subjects
figure(1); clf;
title('Correlation matrices for all subjects')
for iCorrMatrices = 1:size(allSubjectResults.corrMatrices, 3)
    subplot(ceil(sqrt(size(allSubjectResults.corrMatrices, 3))), ...
        ceil(sqrt(size(allSubjectResults.corrMatrices, 3))), ...
        iCorrMatrices)
    imagesc(allSubjectResults.corrMatrices(:,:,iCorrMatrices));
    title(allSubjectResults.dirNames(iCorrMatrices))
end

% find the index numbers for session 1 (A) and two(2) and average the
% correlation matrices for both sessions
indexTmp1 = strfind(allSubjectResults.dirNames, 'A');
indexSes1 = find(not(cellfun('isempty', indexTmp1)));
indexTmp2 = strfind(allSubjectResults.dirNames, 'B');
indexSes2 = find(not(cellfun('isempty', indexTmp2)));
Ses1Matrices = allSubjectResults.corrMatrices(:,:,indexSes1);
Ses2Matrices = allSubjectResults.corrMatrices(:,:,indexSes2);
Ses1Labels = allSubjectResults.dirNames(indexSes1);
Ses2Labels = allSubjectResults.dirNames(indexSes2);
meanSes1Matrices = nanmean(Ses1Matrices, 3);
meanSes2Matrices = nanmean(Ses2Matrices, 3);

% Plot the correlation matrices for both sessions
figure(2); clf;
subplot(1,2,1)
imagesc(meanSes1Matrices);
set(gca, 'XTick', 1:length(allSubjectResults.chanNames));
set(gca, 'YTick', 1:length(allSubjectResults.chanNames));
set(gca, 'XTickLabel', allSubjectResults.chanNames);
set(gca, 'YTickLabel', allSubjectResults.chanNames);
colorbar
title('Session 1')

subplot(1,2,2)
imagesc(meanSes2Matrices);
set(gca, 'XTick', 1:length(allSubjectResults.chanNames));
set(gca, 'YTick', 1:length(allSubjectResults.chanNames));
set(gca, 'XTickLabel', allSubjectResults.chanNames);
set(gca, 'YTickLabel', allSubjectResults.chanNames);
colorbar
title('Session 2')

% Plot a scatter plot of both sessions
figure(3); clf;
scatter(meanSes1Matrices(:), meanSes2Matrices(:))
xlabel('Session 1 (mean connectivity)')
ylabel('Session 2 (mean connectivity)')

cd(PATHS.ROOT)

% plot sessions against eachother for each subject
B = cellfun(@(x) x(1:5),allSubjectResults.dirNames(cellfun('length',allSubjectResults.dirNames) > 1),'un',0);
uniquePPN = unique(B);

for iPPN = 1:length(uniquePPN)
    currPPNindx = find(strncmpi(allSubjectResults.dirNames, uniquePPN{iPPN}, 5) == 1);
    figure(iPPN+3); clf;
    for iMatrices = 1:length(currPPNindx)
        subplot(1,length(currPPNindx),iMatrices)
        imagesc(allSubjectResults.corrMatrices(:,:,currPPNindx(iMatrices)))
        title(allSubjectResults.dirNames(currPPNindx(iMatrices)))
        colorbar
    end
end

        