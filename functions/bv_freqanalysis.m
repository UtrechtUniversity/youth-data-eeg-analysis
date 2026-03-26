function [fd] = bv_freqanalysis(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
saveData    = ft_getopt(cfg, 'saveData');
inputStr    = ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr', 'freq');
freqrange   = ft_getopt(cfg, 'freqrange', [0 100]);
trllength   = ft_getopt(cfg, 'trllength');
quiet       = ft_getopt(cfg, 'quiet');

quiet = strcmpi(quiet, 'yes');

eval('setPaths')
eval('setOptions')

if nargin < 2
    
    try
        load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'], 'subjectdata')
    catch
        error('Subject.mat file not found')
    end
    
    if ~quiet; disp(subjectdata.subjectName); end
    try
        load([subjectdata.PATHS.(inputStr)])
        [~, preprocFilename, ~] = fileparts(subjectdata.PATHS.(inputStr));
        if ~quiet; fprintf('\t %s found and loaded \n', preprocFilename); end
    catch
        errorStr = sprintf('No data input variable given and no data found at subjectdata.PATHS.%s',...
            inputStr);
        error(errorStr)
    end
end

if ~isempty(trllength)
    cfg = [];
    cfg.triallength = 5;
    data = bv_cutAppendedIntoTrials(cfg, data);
    if isempty(data)
        fd = [];
        return
    end
end

if length(data.trial) < 2
    fd = [];
    return
end

if ~quiet; fprintf('\t starting frequency analysis ... '); end

cfg = [];
cfg.method      = 'mtmfft';
cfg.taper       = 'hanning';
cfg.tapsmofrq   = 1;
cfg.output      = 'pow';
cfg.foilim      = [freqrange(1) freqrange(2)];
cfg.pad         ='nextpow2';
evalc('freq = ft_freqanalysis(cfg, data);');
evalc('fd = ft_freqdescriptives(cfg, freq);');

if ~quiet; fprintf('done! \n'); end

if strcmpi(saveData, 'yes')
    
    if quiet 
        evalc('bv_saveData(subjectdata, fd, outputStr);');
    else
        bv_saveData(subjectdata, fd, outputStr);
    end
    
end


