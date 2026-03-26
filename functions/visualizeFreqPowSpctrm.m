function powSpectMean = visualizeFreqPowSpctrm(cfg)
% visualize the power spectrum of given data
%
% Use as
%   visualizeFreqPowSpctrm(cfg)
%
% Additional options should be specified in and configuration struct and
% can be:
%
%   cfg.subjects:       [vector] add vector with the number of the
%                           subjects to be analyzed. Use 'all' if all
%                           subjects need to be analyzed (default:
%                           'all').
%   cfg.triallength:    [double] set the length of the default cut
%                           trials in seconds.
%   cfg.tapsmofrq:      [double] number, the amount of spectral smoothing
%                           through multi-tapering. Note that 4 Hz smoothing
%                           means plus-minus 4 Hz, i.e. a 8 Hz smoothing box.
%   cfg.freqrange:      [vector] frequency range
%   cfg.dataStr         [string] unique string where the data to be
%                           analyzed's filename is ending in
%
% get options
subjects                = ft_getopt(cfg, 'subjects', 'all');
triallength             = ft_getopt(cfg, 'triallength',2);
tapsmofrq               = ft_getopt(cfg, 'tapsmofrq', 1);
freqrange               = ft_getopt(cfg, 'freqrange');
analysisTree            = ft_getopt(cfg, 'analysisTree');
showAll                 = ft_getopt(cfg, 'showAll');

if isempty(freqrange)
    error('Please give a frequency range')
end

% gather standards
setStandards()

% find individual subject folders
subjectFolders = dir([PATHS.SUBJECTS filesep sDirString '*']);
subjectFolderNames = {subjectFolders.name};

if ~strcmp(subjects, 'all')
    subjectFolderNames = subjectFolderNames(subjects);
end

for iFolName = 1:length(subjectFolderNames)

    try
        load([PATHS.SUBJECTS filesep subjectFolderNames{iFolName} filesep 'Subject.mat'])
    catch
        error('ERROR: no Subject.mat found for %s', subjectFolderNames{iFolName})
    end

    cd([subjectdata.PATHS.SUBJECTDIR filesep analysisTree])
    disp(subjectdata.subjectName)

    previousDataFile = dir('*cleaned.mat');
    try
        load(previousDataFile.name)
    catch
        error('ERROR: dataStr = %s not found', dataStr)
    end

    fprintf('\t %s loaded \n', previousDataFile.name)

    if length(data.trial) == 1
        fprintf('\t Continuous data detected: \n \t')
        cfg = [];
        cfg.triallength     = triallength;
        data = cutIntoEpochs(cfg, data);
    end

    cfg = [];
    cfg.method      = 'mtmfft';
    cfg.taper       = 'hanning';
    cfg.output      = 'pow';
    cfg.tapsmofrq   = tapsmofrq;
    cfg.foilim      = freqrange;
    cfg.keeptrials  = 'yes';
    evalc('freq = ft_freqanalysis(cfg, data);');

    powSpectPerChannel(:,:,iFolName) = squeeze(mean(freq.powspctrm,1));
    powSpectMean(iFolName,:) = squeeze(mean(mean(freq.powspctrm,1),2));

    if strcmpi(showAll, 'yes')
        figure(1); clf; plot(freq.freq, powSpectPerChannel)
        title([subjectdata.subjectName ': Powerspectra for all channels'])
        legend(data.label)

        figure(2); clf; plot(freq.freq, powSpectMean(iFolName,:))
        title([subjectdata.subjectName ': Average powerspectrum'])
        drawnow

        fprintf('\t press Space to continue...\n')
        figure(1); figure(2);
        while 1
            [keyIsDown,~,keyCode] = KbCheck;
            if keyIsDown
                if strcmp('space',KbName(keyCode)),
                    break;
                end
            end
        end
    elseif strcmpi(showAll, 'no')
        continue
    else
        error('cfg.showAll: %s unknown variable', showAll)
    end

end
close all;
figure(3); clf;
plot(freq.freq, powSpectMean)
legend(subjectFolderNames)
figure(4); clf;
plot(freq.freq, mean(powSpectMean, 1))
figure(5); clf;
plot(freq.freq, mean(powSpectPerChannel,3))
legend(data.label)
cd(PATHS.ROOT)
