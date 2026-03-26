function freq = bv_powerAnalysis(cfg, data)

inputStr 	= ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr');
currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setPaths');
freqOutput  = ft_getopt(cfg, 'freqOutput','fourier');
saveData    = ft_getopt(cfg, 'saveData');
nTrials     = ft_getopt(cfg, 'nTrials','all');
trigger     = ft_getopt(cfg, 'trigger');
method      = ft_getopt(cfg, 'method');

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
    cfg = [];
    cfg.trials = find(data.trialinfo==trigger);
    data = ft_selectdata(cfg, data);
end


tic
freq = bvLL_frequencyanalysis(data, [1 20], 'fourier') 
toc


