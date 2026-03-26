function bv_findartefacts_standard(cfg)

saveData    = ft_getopt(cfg, 'saveData', 1);
overwrite   = ft_getopt(cfg, 'overwrite',0);
triallength = ft_getopt(cfg, 'triallength', 1);
startSubject = ft_getopt(cfg, 'startSubject', 1);
endSubject  = ft_getopt(cfg, 'endSubject', 'end');
betaLim     = ft_getopt(cfg, 'betaLim');
gammaLim    = ft_getopt(cfg, 'gammaLim');
varLim      = ft_getopt(cfg, 'varLim');
invVarLim   = ft_getopt(cfg, 'invVarLim');
kurtLim     = ft_getopt(cfg, 'kurtLim');
redefineTrial = ft_getopt(cfg, 'redefineTrial');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');
saveCleanedData = ft_getopt(cfg, 'saveCleanedData',0);

eval(optionsFcn)

subjectFolders = dir([PATHS.SUBJECTS filesep '*' sDirString '*' ]);
subjectNames = {subjectFolders.name};

if ischar(startSubject)
    startSubject = find(ismember(subjectNames, startSubject));
end
if ischar(endSubject)
    if strcmp(endSubject, 'end')
        endSubject = length(subjectNames);
    else
        endSubject = find(ismember(subjectNames, endSubject));
    end
end

for iSubjects = startSubject:endSubject
    subjectNameSession = subjectNames{iSubjects};
    disp(subjectNameSession)
    personalSubjectFolder = [PATHS.SUBJECTS filesep subjectNameSession];
    
    dataFile = [subjectNameSession '_preprocessed.mat'];
    freqFile = [subjectNameSession '_freq.mat'];
    paths2dataFile = [personalSubjectFolder filesep dataFile];
    paths2freqFile = [personalSubjectFolder filesep freqFile];
    fprintf('\t Artefact detection \n')

    if exist(paths2dataFile, 'file')
        load(paths2dataFile)
    else
        error('previous data file not found')
    end
    fprintf('\t %s loaded \n', dataFile)
    
    if exist(paths2freqFile, 'file')
        load(paths2freqFile)
    else
        error('previous freq file not found')
    end
    fprintf('\t %s loaded \n', freqFile)
    
    try
        load([personalSubjectFolder filesep 'Subject.mat'])
    catch
        error('\t no Subject.mat file found, please run scripts in correct order');
    end
       
    outputFile = [subjectNameSession '_artefactdef.mat'];
    outputFilePath = [PATHS.SUBJECTS filesep subjectNameSession filesep outputFile];
    
    if exist(outputFilePath, 'var') && ~overwrite
        fprintf('\t output file already found, not overwriting')
        continue
    end
    
    if redefineTrial
        if length(data.trial{1}) ~= data.fsample * triallength
            cfg = [];
            cfg.length = triallength;
            cfg.overlap = 0;
            evalc('data = ft_redefinetrial(cfg, data);');
        end
    end
    
    cfg = [];
    cfg.betaLim     = betaLim;
    cfg.gammaLim    = gammaLim;
    cfg.varLim      = varLim;
    cfg.invVarLim   = invVarLim;
    cfg.kurtLim     = kurtLim;
    [artefactdef, counts] = QC_artefactDetection(cfg, data, freq);
    
    if saveData
        fprintf('\t \t saving artefact definition to %s ... ', outputFile)
        save(outputFilePath, 'artefactdef');
        fprintf('done \n')
    end
    
    if saveCleanedData
        cfg = [];
        cfg.trials = artefactdef.goodTrials;
        evalc('data = ft_selectdata(cfg, data);');
        
        cleanedOutputFile = [subjectNameSession '_cleaned.mat'];
        cleanedOutputFilePath = [PATHS.SUBJECTS filesep subjectNameSession filesep cleanedOutputFile];
        
        fprintf('\t \t saving cleaned data to %s ... ', cleanedOutputFile)
        save(cleanedOutputFilePath, 'data');
        fprintf('done \n')
    end
    
    fprintf('\t \t Artifact analysis done! \n')
    
end