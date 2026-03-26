function [output, subjects] = bv_compareTriallength(cfg)

inputStr        = ft_getopt(cfg, 'inputStr', 'appended');
triallengths    = ft_getopt(cfg, 'triallengths');
showFigures     = ft_getopt(cfg, 'showFigures', 'no');
subject2Compare = ft_getopt(cfg, 'subject2Compare', 'all');
freqBand        = ft_getopt(cfg, 'freqBand');

if isempty(triallengths)
    error('no cfg.triallengths given')
end
if isempty(freqBand)
    error('no cfg.freqBand given')
end

eval('setPaths')
eval('setOptions')

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};

if strcmpi(subject2Compare, 'all')
    subjectVector = 1:length(subjectFolderNames);
else
    subjectVector = find(contains(subjectFolderNames, subject2Compare));
    if isempty(subjectVector)
        error('No subjects found with cfg.subject2Compare= %s \n', subject2Compare)
    end
end

N = length(subjectVector);

counter = 0;
% R = zeros(1,N);
subjects = cell(1,N);
for iSubject = subjectVector
    counter = counter + 1;
    cSubject = subjectFolderNames{iSubject};
    output(counter)
    subjects{counter} = cSubject;
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    
    [~, dataAppend] = bv_check4data(subjectFolderPath, inputStr);
    
    cfg = [];
    cfg.lpfilter    = 'yes';
    cfg.lpfreq      = freqBand(1);
    cfg.hpfilter    = 'yes';
    cfg.hpfreq      = freqBand(2);
    evalc('dataAppendFilt  = ft_preprocessing(cfg, dataAppend);');
    
    cfg = [];
    cfg.triallength = triallengths(1);
    dataAppendShort = bv_cutAppendedIntoTrials(cfg, dataAppendFilt);
    
    cfg = [];
    cfg.triallength = triallengths(2);
    dataAppendLong   = bv_cutAppendedIntoTrials(cfg, dataAppendFilt);
    
    
    PLIsShort = PLI(dataAppendShort.trial, 1);
    PLIsLong = PLI(dataAppendLong.trial, 1);
    
    WsShort = cat(3, PLIsShort{:});
    WsLong = cat(3, PLIsLong{:});
    
    W_Short = squeeze(mean(WsShort,3));
    W_Long = squeeze(mean(WsLong,3));
    
    R_tmp = corr([squareform(W_Short); squareform(W_Long)]');
    output(counter).R = R_tmp(2);
    output(counter).strengthsShort = mean(squareform(W_Short));
    output(counter).strengthsLong  =mean(squareform(W_Long));
    
    if strcmpi(showFigures, 'yes')
        figure(1 + (counter-1)*3)
        subplot(1,2,1)
        imagesc(W_Short)
        setAutoLimits(gca)
        axis square
        colorbar
        colormap viridis
        title(['triallength: ' num2str(triallengths(1))])
        
        subplot(1,2,2)
        imagesc(W_Long)
        setAutoLimits(gca)
        axis square
        colorbar
        colormap viridis
        title(['triallength: ' num2str(triallengths(2))])
        
        figure(2 + (counter-1)*3)
        scatter(squareform(W_Short), squareform(W_Long))
        title(['R^2 = ' num2str(R_tmp(2))])
        
        figure(3 + (counter-1)*3)
        plot(0:triallengths(1):(length(dataAppendShort.trial)-1)*triallengths(1), squeeze(mean(mean(WsShort,1),2)))
        hold on
        plot(0:triallengths(2):(length(dataAppendLong.trial)-1)*triallengths(2), squeeze(mean(mean(WsLong,1),2)))
    end
end




