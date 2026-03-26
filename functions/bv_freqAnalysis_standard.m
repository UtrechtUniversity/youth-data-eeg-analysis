function bv_freqAnalysis_standard(cfg)

freqrange   = ft_getopt(cfg, 'freqrange', [1 100]);
saveData    = ft_getopt(cfg, 'saveData', 1);
overwrite   = ft_getopt(cfg, 'overwrite', 0);
redefineTrial = ft_getopt(cfg, 'redefineTrial');
triallength = ft_getopt(cfg, 'triallength');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');

eval(optionsFcn)

subjectFolders = dir([PATHS.SUBJECTS filesep '*' sDirString '*']);
subjectNames = {subjectFolders.name};

for iSubjects = 1:length(subjectNames);
    subjectNameSession = subjectNames{iSubjects};
    currSubjectName = strsplit(subjectNameSession, '_');
    currSubjectName = currSubjectName{1};
    disp(currSubjectName)
    personalSubjectFolder = [PATHS.SUBJECTS filesep subjectNameSession];
    
    dataFile = [currSubjectName '_preprocessed.mat'];
    paths2dataFile = [personalSubjectFolder filesep dataFile];
    
    if exist(paths2dataFile, 'file')
        load(paths2dataFile)
    else
        error('previous data file not found')
    end
    fprintf('\t %s loaded \n', dataFile)

    try
        load([personalSubjectFolder filesep 'Subject.mat'])
    catch
        error('\t no Subject.mat file found, please run scripts in correct order');
    end
    
    outputFile = [currSubjectName '_freq.mat'];
    outputFilePath = [PATHS.SUBJECTS filesep subjectNameSession filesep outputFile];
    
    if exist(outputFilePath, 'var') && ~overwrite
        fprintf('\t output file already found, not overwriting')
        continue
    end
    
    if redefineTrial
        if (length(data.trial{1}) ~= data.fsample * triallength)
            cfg = [];
            cfg.length = triallength;
            cfg.overlap = 0;
            evalc('data = ft_redefinetrial(cfg, data);');
        end
    end
    
    fprintf('\t freq analysis ... ')

    freq = bvLL_frequencyanalysis(data, freqrange);
    fprintf('done \n')
    
    if saveData
        fprintf('\t \t saving preprocessed data to %s ... ', outputFile)
        save(outputFilePath, 'freq');
        fprintf('done \n')
    end
        
end

