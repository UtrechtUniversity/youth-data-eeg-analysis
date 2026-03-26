function bv_QualityControl

cSubject
optionsFcn
pathFcn

eval(optionsFcn)
eval(pathFcn)

%% Preprocessing
% Loading Subject.mat
subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
[subjectdata] = bv_check4data(subjectFolderPath);

% Loading in data 
cfg = [];
cfg.headerfile = subjectdata.PATHS.HDRFILE;
cfg.dataset = subjectdata.PATHS.DATAFILE;
cfg.channel = 'EEG';
data = ft_preprocessing(cfg)

cfg = [];
cfg.resampleFs  = 512;
cfg.trialfun    = 'trialfun_YOUth_3Y';
cfg.hpfreq      = 0.1;
cfg.notchfreq   = 50;
cfg.currSubject = currSubject;
cfg.optionsFcn  = 'setPaths'; 
cfg.saveData    = 'no';

data = bv_preprocResample(cfg)






% Filtering
% 

% Frequency spectrum

% Artefact detection (which types?)
% 
% 