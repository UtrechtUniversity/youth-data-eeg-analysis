function R = bv_compareFreqband(cfg, connectivity1, connectivity2)

currSubject = ft_getopt(cfg, 'currSubject');
inputStr1   = ft_getopt(cfg, 'inputStr1');
inputStr2   = ft_getopt(cfg, 'inputStr2');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');
saveFigures = ft_getopt(cfg, 'saveFigures');
freqBands   = ft_getopt(cfg, 'freqBands');
freqLabels  = ft_getopt(cfg, 'freqLabels');

if nargin == 1
    disp(currSubject)
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    [subjectdata, connectivity1, connectivity2] = bv_check4data(subjectFolderPath, inputStr1, inputStr2);
end

if nargin > 1 && nargin < 3
    error('Only a single connectivity dataset used as input')
end

for iFreq = 1:length(freqBands)
    currBand = freqBands{iFreq};
    currLabel = freqLabels{iFreq};
    
    freqStart = find(connectivity1.freq == currBand(1);
    freqEnd = find(connectivity1.freq == currBand(2);

    Ws1 = connectivity1.wpli_debiasedspctrm(freqStart:freqEnd);
    Ws2 = connectivity2.wpli_debiasedspctrm(freqStart:freqEnd);

    freqVector = connectivity1.freq;

R = correlateMultipleWs(Ws1, Ws2);
figure; plot(freqVector, R, 'LineWidth', 2);
set(gca, 'XLim', [0 100]);

if strcmpi(saveFigures, 'yes')
    filename = [currSubject '_correlationPerFreq.png'];

    fprintf('\t\t saving figure to %s ... ', filename)
    save([PATHS.RESULTFIGURES filesep filename])
    fprintf('done! \n')
    close all
end

    


