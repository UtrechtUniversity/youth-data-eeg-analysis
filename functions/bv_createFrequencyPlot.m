function [alphaMax, thetaMax] = bv_createFrequencyPlot(cfg)

inputName = ft_getopt(cfg, 'inputName');


eval('setStandards')
subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};
% figure;

for iSubjects = 1:length(subjectFolderNames)
    currSubject = subjectFolderNames{iSubjects};
    disp(currSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputName);
    
    fprintf('\t frequency analysis ... ')
    evalc('freq = bvLL_frequencyanalysis(data, [1 100]);');
    fprintf('done! \n')
    
    meanFreq = squeeze(nanmean(nanmean(freq.powspctrm,1),2));
    
    %     plot(freq.freq, squeeze(nanmean(nanmean(freq.powspctrm,1),2)), 'LineWidth', 2)
    %     hold on
    
    alphaFreqStart = find(freq.freq == 6);
    alphaFreqEnd = find(freq.freq == 13);
    thetaFreqStart = find(freq.freq == 3);
    thetaFreqEnd = find(freq.freq == 6);
    
    alphaFreqRange = freq.freq(alphaFreqStart:alphaFreqEnd);
    thetaFreqRange = freq.freq(thetaFreqStart:thetaFreqEnd);
    alphaRange = meanFreq(alphaFreqStart:alphaFreqEnd);
    thetaRange = meanFreq(thetaFreqStart:thetaFreqEnd);
    
    alphaPeaks = findpeaks(meanFreq(alphaFreqStart:alphaFreqEnd));
    thetaPeaks = findpeaks(meanFreq(thetaFreqStart:thetaFreqEnd));
    
    if ~isempty(alphaPeaks);
        alphaMaxIndx = find(meanFreq(alphaFreqStart:alphaFreqEnd)==max(alphaPeaks));
        alphaMax(iSubjects) = alphaFreqRange(alphaMaxIndx);
    else
        alphaMax(iSubjects) = NaN;
    end
    
    if ~isempty(thetaPeaks)
        thetaMaxIndx = find(meanFreq(thetaFreqStart:thetaFreqEnd)==max(thetaPeaks));
        thetaMax(iSubjects) = thetaFreqRange(thetaMaxIndx);
    else
        thetaMax(iSubjects) = NaN;
    end
    %     figure(1);
    %     plot(alphaFreqRange, meanFreq(alphaFreqStart:alphaFreqEnd))
    %     hold on
    %     plot(alphaFreqRange(alphaMaxIndx), alphaRange(alphaMaxIndx), 'r*', 'MarkerSize', 3);
    %
    %     figure(2);
    %     plot(thetaFreqRange, meanFreq(thetaFreqStart:thetaFreqEnd))
    %     hold on
    %     plot(thetaFreqRange(thetaMaxIndx), thetaRange(thetaMaxIndx), 'r*', 'MarkerSize', 3);
    %
end