function bv_removeSubjects(cfg)

cfg.optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
cfg.pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
cfg.method      = ft_getopt(cfg, 'method','checkfiles');
cfg.mintrials   = ft_getopt(cfg, 'mintrials');
cfg.minchans    = ft_getopt(cfg, 'minchans');
cfg.trialinfo   = ft_getopt(cfg, 'trialinfo', 'all');
cfg.maxbadchans = ft_getopt(cfg, 'maxbadchans');
cfg.inputStr    = ft_getopt(cfg, 'inputStr');

if strcmp(cfg.method, 'checktrials') && isempty(cfg.mintrials)
    error('checking trials while no minimum trials is given')
end
if strcmp(cfg.method, 'checkchannels') && isempty(cfg.minchans)
    error('checking channels while no minimum channels is given')
end

eval(cfg.optionsFcn)
eval(cfg.pathsFcn)

if ~isfield(PATHS, 'REMOVED')
    error('please add REMOVED to PATHS structure, created in your pathsFcn')
end

subjectDirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectNames = {subjectDirs.name};

for iSubj = 1:length(subjectNames)
    currSubject = subjectNames{iSubj};
    disp(currSubject)
    
    try
        load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'], 'subjectdata')
        fprintf('\t Subject.mat found \n')
    catch
        removingSubjects(cfg, currSubject, 'no Subject.mat file found \n')
        continue
    end
    
    if ~isempty(cfg.inputStr)
        if ~isfield(subjectdata.PATHS, upper(cfg.inputStr))
            removingSubjects(cfg, currSubject, sprintf('cfg.inputStr: ''%s'' not found \n', cfg.inputStr))
            continue
        else
            fprintf('\t cfg.inputStr: ''%s'' found \n', cfg.inputStr)
            [subjectdata, data] = bv_check4data(subjectdata.PATHS.SUBJECTDIR, ...
                cfg.inputStr);
        end
    end
    
    switch cfg.method
        case 'checkfiles'
            fprintf('\t all files present \n')
        case 'checktrials'
            % TO DO DO CHECK TRIALS
            if strcmpi(cfg.trialinfo, 'all')
                nTrls = length(data.trial);
            else
                nTrls = sum(data.trialinfo == cfg.trialinfo);
            end
            
            if nTrls < cfg.mintrials
                fprintf('\t !!! too little trials (%s) for trialinfo: %s, removing ... \n', num2str(nTrls), num2str(cfg.trialinfo))
                removingSubjects(cfg, currSubject, sprintf('too little trials (%s)', num2str(nTrls)))
            else
                fprintf('\t enough trials found (%s), not removing ... ', num2str(nTrls))
            end
        case 'checkchannels'
            nChans = length(data.label);
            if nChans < cfg.minchans
                fprintf('\t !!! too little channels (%s), removing ... \n', num2str(nChans))
                removingSubjects(cfg, currSubject, sprintf('too little channels (%s)', num2str(nChans)))
            else
                fprintf('\t enough channels found (%s), not removing ... ', num2str(nChans))
            end
            
        case 'checkmaxbadchans'
            nBadChans = length(subjectdata.channels2remove);
            if nBadChans > cfg.maxbadchans
                fprintf('\t !!! too many bad channels (%1.0f), removing ... \n', nBadChans)
                removingSubjects(cfg, currSubject, sprintf('too many bad channels (%1.0f)', nBadChans))
            else
                fprintf('\t no problems, not removing ... \n ')
            end
    end
    
    fprintf('done! \n')
    
    
    
    
end
