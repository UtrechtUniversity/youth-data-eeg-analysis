function checkTrialsNeeded(dataStr)

try
    dataFile = dir(['*' dataStr '.mat']);
    dataFileName = dataFile.name;
    load(dataFileName)
catch
    errorMsg = ['datafile not found'];
end

splitFileName = strsplit(dataFileName,'_');
ppName = splitFileName{1};
lastAnalysis = splitFileName{end};

cfg = [];
cfg.length = 2;
cfg.overlap = 0;
evalc('data = ft_redefinetrial(cfg, data);');

nTrials = length(data.trial);
trialNRs = 2:(nTrials-1);
usedData = 2:4:nTrials-1;
ft_defaults

nRands = 5;
rng(105000)
globConnectivity = zeros(length(usedData(1:end-1)), nRands);

counter = 0;

fprintf('%s started\n', ppName)
for j = 1:nRands
    randSeed = randi(50000);
    fprintf('randomization: %d\n', j)
    lengthLastMsg = 0;
    tic
    for i = usedData(1:end-1)
        counter = counter + 1;
        rng(randSeed)
        currTrials = datasample(trialNRs,i, 'Replace', false);
        
        cfg = [];
        cfg.trials = currTrials;
        evalc('currData = ft_selectdata(cfg, data);');
        
        cfg = [];
        cfg.method      = 'mtmfft';
        cfg.taper       = 'dpss';
        cfg.output      = 'fourier';
        cfg.tapsmofrq   = 2;
        cfg.foilim      = [4 7];
        cfg.keeptrials  = 'yes';
        evalc('freq = ft_freqanalysis(cfg, currData);');
        
        cfg           = [];
        cfg.method    =  'wpli_debiased';
        evalc('wpli_debiased = ft_connectivityanalysis(cfg, freq);');
        
        globConnectivity(counter,j) = nanmean(nanmean(nanmean(wpli_debiased.wpli_debiasedspctrm,3)));
        
        percDone = ceil((counter / length(usedData(1:end-1)))*100);
        msg = ['   ' num2str(percDone) '% done...'];
        fprintf(repmat('\b', 1, lengthLastMsg));
        fprintf('%s', msg)
        lengthLastMsg = length(msg);
    end
    elapsedTime = toc;
    fprintf('\nrandomization: %d done, which took %d seconds\n', j, elapsedTime)
    counter = 0;
end
fprintf('subject: %s done!\n', ppName)

figure;
plot(globConnectivity)

figure;
hold on
mGlobConnectivity = mean(globConnectivity, 2);
SEs = std(globConnectivity,0,2)./sqrt(size(globConnectivity,2));
plot(mGlobConnectivity,'*')
plot(mGlobConnectivity + 2.*SEs,'.')
plot(mGlobConnectivity - 2.*SEs,'.')
hold off

savedFileName = ['globConnectivity_' lastAnalysis '.mat'];
fprintf('saving: %s...', savedFileName)
save(savedFileName,'globConnectivity')
fprintf('done!\n')