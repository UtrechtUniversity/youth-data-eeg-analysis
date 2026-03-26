function [freq] = bv_freqanalysisMarissa(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
saveData    = ft_getopt(cfg, 'saveData');
inputName   = ft_getopt(cfg, 'inputName');
outputName  = ft_getopt(cfg, 'outputName', 'freq');
freqrange   = ft_getopt(cfg, 'freqrange', [0 100]);
quiet       = ft_getopt(cfg, 'quiet', 'no');
trllength   = ft_getopt(cfg, 'trllength', 5);
trloverlap  = ft_getopt(cfg, 'trloverlap', 0.75);

quiet = strcmpi(quiet,'yes');

eval('setPaths')
eval('setOptions')

if nargin < 2
        
    if quiet
        evalc('[subjectdata, ~, data] = bv_check4data([PATHS.SUBJECTS filesep currSubject], inputName);');
    else
        disp(currSubject)
        [subjectdata, ~, data] = bv_check4data([PATHS.SUBJECTS filesep currSubject], inputName);
    end

end

if ~quiet; fprintf('\t redefining trials (length: %1.0f, overlap %1.2f) ... ', trllength, trloverlap); end

enoughData = any(((diff(data.sampleinfo, [],2)+1)./data.fsample) > trllength);

if ~enoughData
    freq = [];
    return
end

cfg = [];
cfg.length = trllength;
cfg.overlap = 0.75;
evalc('data = ft_redefinetrial(cfg, data);');

if ~quiet 
    fprintf('done! \n')
    fprintf('\t calculating frequency spectrum ... ')
end

cfg = [];
cfg.method = 'mtmfft';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foilim = freqrange;
cfg.tapsmofrq = 8;
cfg.pad = 'nextpow2';
evalc('freq = ft_freqanalysis(cfg, data);');
freq.trialinfo = data.trialinfo;

if ~quiet; fprintf('done! \n'); end

if strcmpi(saveData, 'yes')
    
    if quiet
        evalc('bv_saveData(subjectdata, freq, outputName)');
    else
        bv_saveData(subjectdata, freq, outputName)
    end
    
end


