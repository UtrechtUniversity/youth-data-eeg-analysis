function bv_preprocess_standard(cfg)

hpfilter                = ft_getopt(cfg, 'hpfilter',1);
hpfreq                  = ft_getopt(cfg, 'hpfreq',1);
bsfilter                = ft_getopt(cfg, 'bsfilter',1);
bsfreq                  = ft_getopt(cfg, 'bsfreq', [48 52; 98 102]);
resample                = ft_getopt(cfg, 'resample', 1);
resamplefs              = ft_getopt(cfg, 'resamplefs', 512);
reref                   = ft_getopt(cfg, 'reref', 1);
refElectrode            = ft_getopt(cfg, 'refElectrode');
% trigger                 = ft_getopt(cfg, 'trigger', [11 12]);
rmBadChannelsPreprocess = ft_getopt(cfg, 'rmBadChannelsPreprocess', 0);
saveData                = ft_getopt(cfg, 'saveData', 1);
overwrite               = ft_getopt(cfg, 'overwrite', 0);
optionsFcn              = ft_getopt(cfg, 'optionsFcn');
startSubject            = ft_getopt(cfg, 'startSubject');
endSubject              = ft_getopt(cfg, 'endSubject');
trialfun                = ft_getopt(cfg, 'trialfun');

eval(optionsFcn)

subjectFiles = dir([PATHS.SUBJECTS filesep '*' sDirString '*']);
subjectNames = {subjectFiles.name};

rmChannels = {};
if rmBadChannelsPreprocess
    cfg = [];
    cfg.startSubject = 1;
    cfg.endSubject = 'end';
    cfg.analysisTree = [];
    cfg.structFileName = 'Subject.mat';
    cfg.structVarFname = 'subjectdata';
    cfg.fields = {'removedchannels'};
    [rmChannelsAllSubjects, names] = readOutStructFromFile(cfg);
end

if ischar(startSubject)
    startSubject = find(ismember(subjectNames, startSubject));
end
if ischar(endSubject)
    if strcmp(endSubject, 'last')
        endSubject = length(subjectNames);
    else
        endSubject = find(ismember(subjectNames, endSubject));
    end
end

for iSubject = startSubject:endSubject;
    currSubjectNameSession = subjectNames{iSubject};
    currSubjectName = strsplit(currSubjectNameSession, '_');
    currSubjectName = currSubjectName{1};
    disp(currSubjectName)
    if rmBadChannelsPreprocess
        subjectName = subjectNameSession(1:end-1);
        ppnIndx = not(cellfun(@isempty, strfind(names, subjectName)));
    end
    
    subjectFolder = [PATHS.SUBJECTS filesep currSubjectNameSession];
    
    try 
        load([subjectFolder filesep 'Subject.mat'])
    catch
        error('\t no Subject.mat file found, please run scripts in correct order');
    end
    
    cd(subjectdata.PATHS.SUBJECTDIR)
    
    rawName = subjectdata.filename;
    fprintf('\t %s loaded \n', rawName)
       
    outputFile = [currSubjectName '_preprocessed.mat'];
    outputFilePath = [PATHS.SUBJECTS filesep currSubjectNameSession filesep outputFile];
    
    if exist(outputFilePath, 'var') && ~overwrite
        fprintf('\t output file already found, not overwriting')
        continue
    end
       
    if ~isempty(channels2beAnalyzed)
        channels = channels2beAnalyzed;
    else
        channels = 'EEG';
    end
    if rmBadChannelsPreprocess
        rmChannels = rmChannelsAllSubjects(ppnIndx,:);
        rmChannels = rmChannels(not(cellfun(@isempty, rmChannels)));
        rmChannels = unique(rmChannels);
        removedChannels = strcat('-', rmChannels);
        if ~isempty(removedChannels)
            channels = cat(2,channels,removedChannels');
        end
    end
    
    subjectdata.removedchannelsPreprocess = rmChannels;
    
    fprintf(['\t Channels to be removed while preprocessing: ' repmat('%s ', 1, length(rmChannels)) '\n'], rmChannels{:})
    
    cfg = [];
    
    cfg.headerfile  = subjectdata.PATHS.DATAFILE;
    cfg.dataset     = subjectdata.PATHS.DATAFILE;
    cfg.hpfilter    = hpfilter;
    cfg.hpfreq      = hpfreq;
    cfg.bsfilter    = bsfilter;
    cfg.bsfreq      = bsfreq;
    cfg.resample    = resample;
    cfg.resamplefs  = resamplefs;
    cfg.dataset     = dataset;
    cfg.channels    = channels;
    cfg.trigger     = triggers.value;
    cfg.refElectrode = refElectrode;
    cfg.reref       = reref;
    cfg.trialfun    = trialfun;
    
    data = bvLL_preprocessing(cfg);
    
    if saveData
        fprintf('\t saving %s ... ', outputFile)
        save([PATHS.SUBJECTS filesep currSubjectNameSession filesep outputFile], 'data')
        fprintf('done \n')
        
        fprintf('\t saving Subject.mat ... ')
        save([subjectFolder filesep 'Subject.mat'], 'subjectdata')
        fprintf('done \n')
    end
    
end
cd(PATHS.ROOT)
