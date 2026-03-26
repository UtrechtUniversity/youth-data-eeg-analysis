function chans2remove = bv_setChannelsToBeRemoved(cfg, data)

optionsFcn = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject = ft_getopt(cfg, 'currSubject');

if nargin < 2
    hasdata = false;
else
    hasdata = true;
end

if ~hasdata % check whether data needs to be loaded from subject.mat file
    
    if isempty(currSubject)
        error('no input data and no cfg.currSubject')
    end
    
    eval(pathsFcn)
    eval(optionsFcn)
    % Try to load in individuals Subject.mat. If unknown --> throw error.
    try
        load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'], 'subjectdata')
    catch
        error('Subject.mat file not found')
    end
    
    disp(subjectdata.subjectName)
    
    fprintf('\t preprocessing data ... ')
    
    cfg = [];
    cfg.headerfile = subjectdata.PATHS.HDRFILE;
    cfg.dataset = subjectdata.PATHS.DATAFILE;
    cfg.trialfun = OPTIONS.trialfun;
    cfg.Fs = 2048;
    evalc('cfg = ft_definetrial(cfg);');
    cfg.hpfilter = 'yes';
    cfg.hpfreq = 0.16;
    cfg.hpinstabilityfix = 'reduce';
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [48 52];
    cfg.channel = 'EEG';
    evalc('data = ft_preprocessing(cfg);');
    fprintf('done! \n')
    
end

fprintf('\t cutting in 2 second trials and visual inspection ... ')
cfg = [];
cfg.length = 2;
cfg.overlap = 0;
evalc('data = ft_redefinetrial(cfg, data);');

cfg = [];
cfg.method = 'summary';
cfg.layout = 'biosemi32.lay';
cfg.keeptrial = 'yes';
cfg.keepchannel = 'nan';
evalc('data = ft_rejectvisual(cfg, data);');
fprintf('done! \n')

trialdata = [data.trial{:}];
chans2remove =  data.label(sum(isnan(trialdata),2) == size(trialdata,2));
subjectdata.channels2remove = chans2remove;

if isempty(chans2remove)
    fprintf('\t no channels will be removed from analysis!')
else
    fprintf(['\t the following channels will be removed from analysis ... \n \t \t ' ...
        repmat('%s, ', 1, length(chans2remove))], chans2remove{:})
end

if ~hasdata
    bv_saveData(subjectdata)
end