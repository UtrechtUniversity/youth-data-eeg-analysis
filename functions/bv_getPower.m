function freq = bv_getPower(cfg, data)

inputStr 	= ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr');
currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setPaths');
saveData    = ft_getopt(cfg, 'saveData');
trigger     = ft_getopt(cfg, 'trigger');

if nargin < 2
    disp(currSubject)
    
    eval(optionsFcn)
    eval('setOptions')
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    try
        [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    catch
        fprintf('\t previous data not found, skipping ... \n')
        connectivity = [];
        return
    end
    
    subjectdata.cfgs.(outputStr) = cfg;
    
end

if ~isempty(trigger)
    if ~any(ismember(trigger, data.trialinfo))
        freq = [];
        return
    end
    
    cfg = [];
    cfg.trials = find(data.trialinfo==trigger);
    evalc('data = ft_selectdata(cfg, data);');
end

cfg = [];
cfg.method = 'wavelet';
cfg.output = 'pow';
cfg.foi = 1:20;
cfg.toi = 1:60;
evalc('freq = ft_freqanalysis(cfg, data);');

if strcmpi(saveData, 'yes')
    bv_saveData(subjectdata, freq, outputStr)
end