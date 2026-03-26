function detectCleanTrials_testRetest( cfg )

saveData        = ft_getopt(cfg, 'saveData', 1);
origtriallength = ft_getopt(cfg, 'origtriallength', 1);
triallength2use = ft_getopt(cfg, 'triallength2use', 5);
rmBadChannels   = ft_getopt(cfg, 'rmBadChannels', 0);
startSubject    = ft_getopt(cfg, 'startSubject', 1);
endSubject      = ft_getopt(cfg, 'endSubject', 'end');
optionsFcn      = ft_getopt(cfg, 'optionsFcn');
redefineTrial   = ft_getopt(cfg, 'redefineTrial');

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


for iSubjects = startSubject:endSubject;
    subjectNameSession = subjectNames{iSubjects};
    disp(subjectNameSession)
    personalSubjectFolder = [PATHS.SUBJECTS filesep subjectNameSession];
    
    dataFile = [subjectNameSession '_preprocessed.mat'];
    artefactdefFile = [subjectNameSession '_artefactdef.mat'];
    freqFile = [subjectNameSession '_freq.mat'];
    paths2dataFile = [personalSubjectFolder filesep dataFile];
    paths2artefacdefFile = [personalSubjectFolder filesep artefactdefFile];
    paths2freqFile = [personalSubjectFolder filesep freqFile];
    if exist(paths2dataFile, 'file')
        load(paths2dataFile)
    else
        error('previous data file not found')
    end
    fprintf('\t %s loaded \n', dataFile)
    
    if exist(paths2artefacdefFile, 'file')
        load(paths2artefacdefFile)
    else
        error(' artefactdef file not found')
    end
    fprintf('\t %s loaded \n', artefactdefFile)
    
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
    
    if redefineTrial
        if length(data.trial{1}) ~= data.fsample * origtriallength
            cfg = [];
            cfg.length = origtriallength;
            cfg.overlap = 0;
            evalc('data = ft_redefinetrial(cfg, data);');
        end
    end
    
    
    fprintf('\t Counting good trials with a length of %s seconds \n', num2str(triallength2use))
    while 1
        
        if rmBadChannels
            cleanedString = '_cleaned';
        else
            cleanedString = [];
        end
        
        if ~isempty(artefactdef.goodTrials)
            conditionSwitch = [find( diff( data.trialinfo ) ~= 0); length(data.trialinfo)];
            nConditions = max(conditionSwitch)/min(conditionSwitch);
            lConditions = min(conditionSwitch);
            conditions = [conditionSwitch data.trialinfo( conditionSwitch')];
            
            if triallength2use == (length(data.trial{1}) / data.fsample)
                trlInfo = [artefactdef.goodTrials', artefactdef.goodTrials' + 1, data.trialinfo(artefactdef.goodTrials)];
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
                
                diffBetweenTrials = diff([vGoodSampleinfo Inf]);
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
            end
            
            if isempty(trlInfo)
                trials2Use = 0;
                
                if rmBadChannels
                    subjectdata.cleaned.withoutBadChannels.total = trials2Use;
                else
                    subjectdata.cleaned.withBadChannels.total = trials2Use;
                end
                
                conditionInfo = unique(data.trialinfo);
                fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
                for i = 1:length(conditionInfo)
                    fieldname = ['condition' num2str(conditionInfo(i)) cleanedString];
                    
                    if rmBadChannels
                        subjectdata.cleaned.withoutBadChannels.(fieldname) = 0;
                        fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withoutBadChannels.(fieldname)), num2str(conditionInfo(i)))
                    else
                        subjectdata.cleaned.withBadChannels.(fieldname) = 0;
                        fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withBadChannels.(fieldname)), num2str(conditionInfo(i)))
                    end
                    
                end
                break
            end
            
            [a, b] = hist(trlInfo(:,3), unique(conditions(:,2)));
            
            trials2Use = size(trlInfo, 1);
            
            if rmBadChannels
                subjectdata.cleaned.withoutBadChannels.total = trials2Use;
            else
                subjectdata.cleaned.withBadChannels.total = trials2Use;
            end
            
            fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
            for i = 1:length(a)
                fieldname = ['condition' num2str(b(i)) cleanedString];
                
                if rmBadChannels
                    subjectdata.cleaned.withoutBadChannels.(fieldname) = a(i);
                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withoutBadChannels.(fieldname)), num2str(b(i)))
                else
                    subjectdata.cleaned.withBadChannels.(fieldname) = a(i);
                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withBadChannels.(fieldname)), num2str(b(i)))
                end
                
            end
            
        else
            
            trials2Use = 0;
            conditionInfo = unique(data.trialinfo);
            fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
            
            if rmBadChannels
                subjectdata.cleaned.withoutBadChannels.total = trials2Use;
            else
                subjectdata.cleaned.withBadChannels.total = trials2Use;
            end
            
            for i = 1:length(conditionInfo)
                fieldname = ['condition' num2str(conditionInfo(i)) cleanedString];
                
                if rmBadChannels
                    subjectdata.cleaned.withoutBadChannels.(fieldname) = 0;
                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withoutBadChannels.(fieldname)), num2str(conditionInfo(i)))
                else
                    subjectdata.cleaned.withBadChannels.(fieldname) = 0;
                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.cleaned.withBadChannels.(fieldname)), num2str(conditionInfo(i)))
                end
                
            end
        end
        break
        
    end
    fprintf('\t \t saving good trials to Subject.mat file...')
    save([personalSubjectFolder filesep 'Subject.mat'], 'subjectdata');
    fprintf('done \n')
end