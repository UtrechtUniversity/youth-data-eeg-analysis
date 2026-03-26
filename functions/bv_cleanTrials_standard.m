function cleanTrials_testRetest(cfg)

saveData        = ft_getopt(cfg, 'saveData', 1);
origtriallength = ft_getopt(cfg, 'origtriallength', 1);
triallength2use = ft_getopt(cfg, 'triallength2use', 5);
startSubject    = ft_getopt(cfg, 'startSubject', 1);
endSubject      = ft_getopt(cfg, 'endSubject', 'end');
redefineTrial   = ft_getopt(cfg, 'redefineTrial');
optionsFcn      = ft_getopt(cfg, 'optionsFcn');

eval(optionsFcn)

subjectFolders = dir([PATHS.SUBJECTS filesep '*' sDirString '*']);
subjectNames = {subjectFolders.name};

if ischar(startSubject)
    startSubject = find(~cellfun(@isempty, strfind(subjectNames, startSubject)));
end
if ischar(endSubject)
    if strcmp(endSubject, 'end')
        endSubject = length(subjectNames);
    else
        endSubject = find(~cellfun(@isempty, strfind(subjectNames, endSubject)));
    end
end

for iSubjects = startSubject:endSubject
    subjectNameSession = subjectNames{iSubjects};
    disp(subjectNameSession)
    personalSubjectFolder = [PATHS.SUBJECTS filesep subjectNameSession];
    
    dataFile = [subjectNameSession '_preprocessed.mat'];
    artefactFile = [subjectNameSession '_artefactdef.mat'];
    paths2dataFile = [personalSubjectFolder filesep dataFile];
    paths2artefactFile = [personalSubjectFolder filesep artefactFile];
    fprintf('\t clean trials \n')
    
    if exist(paths2dataFile, 'file')
        load(paths2dataFile)
    else
        error('previous data file not found')
    end
    fprintf('\t %s loaded \n', dataFile)
    
    if exist(paths2artefactFile, 'file')
        load(paths2artefactFile)
    else
        error('previous artefactdef file not found')
    end
    fprintf('\t %s loaded \n', artefactFile)
    
    try
        load([personalSubjectFolder filesep 'Subject.mat'])
    catch
        error('\t no Subject.mat file found, please run scripts in correct order');
    end
    
    outputFile = [subjectNameSession '_cleaned.mat'];
    outputFilePath = [PATHS.SUBJECTS filesep subjectNameSession filesep outputFile];
    
    if redefineTrial
        if length(data.trial{1}) ~= data.fsample * origtriallength
            cfg = [];
            cfg.length = origtriallength;
            cfg.overlap = 0;
            evalc('data = ft_redefinetrial(cfg, data);');
        end
    end
    
    conditionSwitch = [find( diff( data.trialinfo ) ~= 0); length(data.trialinfo)];
    nConditions = max(conditionSwitch)/min(conditionSwitch);
    lConditions = min(conditionSwitch);
    conditions = [conditionSwitch data.trialinfo( conditionSwitch')];
    unConditions = unique(conditions(:,2));
    
    if triallength2use == length(data.trial{1}) / data.fsample
        cfg = [];
        cfg.trials = artefactdef.goodTrials;
        
        evalc('newData = ft_selectdata(cfg, data);');
    else
        
        vConditions = [];
        for iCond = 1:nConditions
            vConditions = [vConditions repmat(iCond, 1, lConditions)];
        end
        
        vGoodConditions = vConditions(artefactdef.goodTrials);
        goodSampleinfo = data.sampleinfo(artefactdef.goodTrials, :);
        goodSampleinfo(:,1) = goodSampleinfo(:,1)+vGoodConditions';
        goodSampleinfo(:,2) = goodSampleinfo(:,2)+vGoodConditions';
        
        vGoodSampleinfo = [];
        for i = 1: size(goodSampleinfo, 1)
            vGoodSampleinfo = [vGoodSampleinfo goodSampleinfo(i,1):goodSampleinfo(i,2)];
        end
        
        diffBetweenTrials = diff([vGoodSampleinfo inf]);
        badTrialsIndx = find(diffBetweenTrials>1);
        lnghtConseqSamples = diff([0 badTrialsIndx]);
        
        trlsWthGoodLength = find(lnghtConseqSamples >= triallength2use * data.fsample);
        
        trlStarts = [];
        trlEnds = [];
        for i = 1:length(trlsWthGoodLength)
            
            trlStart = artefactdef.goodTrials(sum(lnghtConseqSamples(1:(trlsWthGoodLength(i)-1))) ./ data.fsample + 1);
            trlEnd = artefactdef.goodTrials(sum(lnghtConseqSamples(1:trlsWthGoodLength(i))) ./ data.fsample);
            trlLength = length(trlStart:trlEnd);
            noTrials = floor((trlLength*origtriallength)./triallength2use);
            trialVector = 0:1:noTrials-1;
            currTrlStarts = trlStart + (trialVector.*(triallength2use/origtriallength));
            trlStarts = [trlStarts; currTrlStarts'];
            currTrlEnds = currTrlStarts + triallength2use;
            trlEnds = [trlEnds; currTrlEnds'];
            
        end
        trlEnds = trlEnds - 1;
        trlInfo = [trlStarts trlEnds zeros(length(trlStarts),1)];
        
        for i = 1:size(trlInfo,1)
            conditions2use = conditions(conditions(:,1) >= trlInfo(i,1),:);
            trlInfo(i,3) = conditions2use(1,2);
        end
        
        goodTrials = [];
        for i = 1:length(trlStarts)
            goodTrials = [goodTrials, trlStarts(i):trlEnds(i)];
        end
        
        newData = data;
        newData = rmfield(newData, 'trial');
        newData = rmfield(newData, 'time');
        newData = rmfield(newData, 'trialinfo');
        newData = rmfield(newData, 'sampleinfo');
        for i = 1:length(trlStarts)
            newData.trial{i} = [data.trial{trlStarts(i):(trlEnds(i)-1)}];
            newData.time{i} = [data.time{trlStarts(i):(trlEnds(i)-1)}];
            newData.sampleinfo(i,:) = [data.sampleinfo(trlStarts(i)) data.sampleinfo(trlEnds(i),2)];
            newData.trialinfo(i,1) = data.trialinfo(trlStarts(i));
        end
    end
    
    [a] = hist(newData.trialinfo, unConditions);
    fprintf('\t %s trials in total with: \n', num2str(a(1)+a(2)))
    fprintf('\t \t %s trials in condition %s \n', num2str(a(1)), num2str(unConditions(1)))
    fprintf('\t \t %s trials in condition %s \n', num2str(a(2)),num2str(unConditions(1)))
    
    data = newData;
    
    if saveData
        fprintf('\t \t saving preprocessed data to %s ... ', outputFile)
        save(outputFilePath, 'data');
        fprintf('done \n')
    end
    
    clear newData goodTrials vGoodSampleinfo artefactdef
    
end