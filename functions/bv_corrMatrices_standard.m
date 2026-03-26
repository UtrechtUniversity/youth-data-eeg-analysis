function bv_corrMatrices_standard(cfg)

freqrange       = ft_getopt(cfg, 'freqrange');
overwrite       = ft_getopt(cfg, 'overwrite', 0);
corrMethod      = ft_getopt(cfg, 'corrMethod');
clnDataStr      = ft_getopt(cfg, 'clnDataStr', 'cleaned');
saveData        = ft_getopt(cfg, 'saveData', 1);
outputStr       = ft_getopt(cfg, 'outputStr');
optionsFcn      = ft_getopt(cfg, 'optionsFcn');
noTrials        = ft_getopt(cfg, 'noTrials');

eval(optionsFcn)

subjectFolders = dir([PATHS.SUBJECTS filesep '*' sDirString '*']);
subjectNames = {subjectFolders.name};

outputFile = ['corrMatrices_' corrMethod '_' outputStr '.mat'];
path2outputfile = [PATHS.RESULTS filesep outputFile];
counter = 0;
for iSubject = 1:length(subjectNames);
    subjectNameSession = subjectNames{iSubject};
    disp(subjectNameSession)
    personalSubjectFolder = [PATHS.SUBJECTS filesep subjectNameSession];
    
    dataFile = [subjectNameSession '_cleaned.mat'];
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
    
    for iTrig = 1:length(triggers.value)
        
        counter = counter + 1;
        
        triggerIndx = find(data.trialinfo == triggers.value(iTrig));
        
        fprintf(['\t ' triggers.label{iTrig} '\n'])
        personalOutputFile = [ subjectNameSession '_corrMatrices_' corrMethod '_' outputStr '_' triggers.label{iTrig} '.mat'];
        path2personalOutputFile = [personalSubjectFolder filesep personalOutputFile];
        
        if exist(path2personalOutputFile, 'file') && ~overwrite
            load(path2personalOutputFile)
            % store data in struct
            allSubjectResults.corrMatrices(:,:,iSubject,iTrig) = cMatrix;
            allSubjectResults.session{iSubject} = subjectdata.condition;
            allSubjectResults.subjects{iSubject} = subjectdata.subjectName;
            fprintf('\t \t Correlation matrices already exist, not overwriting \n')
            continue
        end
        if ~exist(path2personalOutputFile, 'file') || overwrite
            
            switch corrMethod
                case 'wpli_debiased'
                    fprintf('\t \t frequency analysis before connectivity analysis ... ')
                    
                    while 1
                        
                        if length(triggerIndx) < noTrials
                            warning('/t /t no %s trials found', num2str(noTrials))
                            cMatrix = nan(size(data.trial{1},1), size(data.trial{1},1));
                            break
                        end
                        
                        cfg = [];
                        cfg.method      = 'mtmfft';
                        cfg.taper       = 'dpss';
                        cfg.output      = 'fourier';
                        cfg.tapsmofrq   = 2;
                        cfg.foilim      = freqrange;
                        cfg.keeptrials  = 'yes';
                        cfg.trials      = triggerIndx(1:noTrials);
                        evalc('freq = ft_freqanalysis(cfg, data);');
                        fprintf('done \n')
                        
                        frequencyVector = freq.freq;
                        
                        fprintf(['\t \t connectivity analysis with ' corrMethod ' ... '])
                        cfg           = [];
                        cfg.method    =  'wpli_debiased';
                        evalc('wpli_debiased = ft_connectivityanalysis(cfg, freq);');
                        fprintf('done \n')
                        
                        cMatrix = squeeze(mean(wpli_debiased.wpli_debiasedspctrm,3));
                        break
                    end
                    
                    if ~isempty(subjectdata.removedchannelsPreprocess)
                        boolChanDeleted = true;
                        chansDeleted = subjectdata.removedchannelsPreprocess;
                        allLabelsInOrder = cat(1, data.label, chansDeleted);
                    else
                        boolChanDeleted = false;
                        allLabelsInOrder = data.label;
                        chansDeleted = [];
                    end
                    
                case 'wpli'
                    fprintf('\t \t frequency analysis before connectivity analysis ... ')
                    
                    while 1
                        
                        if length(triggerIndx) < noTrials
                            warning('/t /t no %s trials found', num2str(noTrials))
                            cMatrix = nan(size(data.trial{1},1), size(data.trial{1},1));
                            break
                        end
                        
                        cfg = [];
                        cfg.method      = 'mtmfft';
                        cfg.taper       = 'dpss';
                        cfg.output      = 'fourier';
                        cfg.tapsmofrq   = 2;
                        cfg.foilim      = freqrange;
                        cfg.keeptrials  = 'yes';
                        cfg.trials      = triggerIndx(1:noTrials);
                        evalc('freq = ft_freqanalysis(cfg, data);');
                        fprintf('done \n')
                        
                        frequencyVector = freq.freq;
                        
                        fprintf(['\t \t connectivity analysis with ' corrMethod ' ... '])
                        cfg           = [];
                        cfg.method    =  'wpli';
                        evalc('wpli = ft_connectivityanalysis(cfg, freq);');
                        fprintf('done \n')
                        
                        cMatrix = squeeze(mean(wpli.wplispctrm,3));
                        break
                    end
                    
                    if ~isempty(subjectdata.removedchannelsPreprocess)
                        boolChanDeleted = true;
                        chansDeleted = subjectdata.removedchannelsPreprocess;
                        allLabelsInOrder = cat(1, data.label, chansDeleted);
                    else
                        boolChanDeleted = false;
                        allLabelsInOrder = data.label;
                        chansDeleted = [];
                    end
                    
                case 'pli'
                    
                    while 1
                        
                        if length(triggerIndx) < noTrials
                            warning('/t /t no %s trials found', num2str(noTrials))
                            cMatrix = nan(size(data.trial{1},1), size(data.trial{1},1));
                            break
                        end
                        
                        fprintf('\t \t selecting trials and bandpass filtering at %s ... ', ['[', num2str(freqrange(1)), ' ', num2str(freqrange(2)), ']'])
                        cfg = [];
                        cfg.trials = triggerIndx(1:noTrials);
                        evalc('dataSel = ft_selectdata(cfg, data);');
                        dat = dataSel.trial;
                        
                        Fs = data.fsample;
                        
                        [filt] = bv_butterFilter(dat, freqrange, Fs);
                        fprintf('done \n')
                        
                        PLIperTrial = PLI(filt, 2);
                        Ws = cat(3, PLIperTrial{:});
                        
                        cMatrix = mean(Ws(:,:,1:noTrials),3);
                        break
                    end
                    
                    if ~isempty(subjectdata.removedchannelsPreprocess)
                        boolChanDeleted = true;
                        chansDeleted = subjectdata.removedchannelsPreprocess;
                        allLabelsInOrder = cat(1, data.label, chansDeleted);
                    else
                        boolChanDeleted = false;
                        allLabelsInOrder = data.label;
                        chansDeleted = [];
                    end
                    
                case 'coh'
                    
                    while 1
                    if length(triggerIndx) < noTrials
                        warning('/t /t no %s trials found', num2str(noTrials))
                        cMatrix = nan(size(data.trial{1},1), size(data.trial{1},1));
                        break
                    end
                    
                    
                        cfg = [];
                        cfg.method      = 'mtmfft';
                        cfg.taper       = 'dpss';
                        cfg.output      = 'fourier';
                        cfg.tapsmofrq   = 2;
                        cfg.foilim      = freqrange;
                        cfg.keeptrials  = 'yes';
                        cfg.trials      = triggerIndx(1:noTrials);
                        evalc('freq = ft_freqanalysis(cfg, data);');
                        
                        frequencyVector = freq.freq;
                        
                        fprintf(['\t \t connectivity analysis with ' corrMethod ' ... '])
                        cfg           = [];
                        cfg.method      =  'coh';
                        evalc('coh = ft_connectivityanalysis(cfg, freq);');
                        fprintf('done \n')
                        
                        cMatrix = squeeze(mean(coh.cohspctrm,3));
                        break
                    end
                    
                    if ~isempty(subjectdata.removedchannelsPreprocess)
                        boolChanDeleted = true;
                        chansDeleted = subjectdata.removedchannelsPreprocess;
                        allLabelsInOrder = cat(1, data.label, chansDeleted);
                    else
                        boolChanDeleted = false;
                        allLabelsInOrder = data.label;
                        chansDeleted = [];
                    end
            end
            
            if boolChanDeleted
                cMatrix(end + 1: end + length(chansDeleted), 1:end,:) = NaN;
                cMatrix(1:end, end + 1 : end + length(chansDeleted),:) = NaN;
            end
            
            % sort both channels and cMatrix on allLabelsInOrder order, to
            % ensure all corr_matrices are equal
            [~, sortIdx] = sort(allLabelsInOrder);
            allSubjectResults.chanNames = allLabelsInOrder(sortIdx);
            cMatrix = cMatrix(sortIdx, sortIdx);
            
            % store data in struct
            allSubjectResults.trigger{counter} = triggers.label{iTrig};
            allSubjectResults.corrMatrices(:,:,counter) = cMatrix;
            allSubjectResults.condition{counter} = subjectdata.condition;
            allSubjectResults.subjects{counter} = subjectdata.subjectName;
            allSubjectResults.removedChannels{counter,:} = chansDeleted;
            
            if saveData
                fprintf('\t \t Saving individual correlation matrix as %s ...', personalOutputFile)
                save([path2personalOutputFile], 'cMatrix')
                fprintf(' done \n')
            end
            
            clear cMatrix freq
        end
        
    end
    clear subjectdata
end

% allSubjectResults.freq = frequencyVector;

cd( PATHS.ROOT )
fprintf('\n \n')

if saveData
    fprintf('\t Saving all correlation matrices in %s ...', outputFile)
    save(path2outputfile, 'allSubjectResults')
    fprintf(' done \n')
end




