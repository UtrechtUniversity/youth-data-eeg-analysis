function [ rmComp ] = automaticCompRemoval(cfg, data, comp, freq)

blinkremoval = ft_getopt(cfg, 'blinkremoval');
gammaremoval = ft_getopt(cfg, 'gammaremoval');
deltaremoval = ft_getopt(cfg, 'deltaremoval');
rmComp = [];

if strcmpi(deltaremoval, 'yes') || strcmpi(gammaremoval, 'yes')
    freqRemoval = true(1);
end

if strcmpi(blinkremoval, 'yes')
    
    fprintf('\t searching for blink component ... ')
    
    clear R
    ring1 = not(cellfun(@isempty, strfind(data.label, 'Fp')));
    ring2 = not(cellfun(@isempty, strfind(data.label, 'AF')));
    ring3 = not(cellfun(@isempty, regexp(data.label, '^F[1234567890z]')));
    ring4 = not(cellfun(@isempty, regexp(data.label, '^FC[1234567890z]')));
    ring5 = not(cellfun(@isempty, regexp(data.label, '^C[1234567890z]')));
    % ring6 = not(cellfun(@isempty, regexp(data.label, '^CP[1234567890z]'))) ...
    %     | not(cellfun(@isempty, regexp(data.label, '^TP[78910]')));
    prefrontalIndx = ring1 | ring2 ;
    frontalIndx = ring1 | ring2 | ring3 | ring4 | ring5;
    
    trialdata   = [data.trial{:}];
    frontaldata = trialdata(frontalIndx,:);
    compdata    = [comp.trial{:}];
    
    R = corr(trialdata', compdata');
    
    [~, sortIndx] = sort(mean(abs(R(prefrontalIndx,:))), 'descend');
    
    %     load('~/git/eeg-graphmetrics-processing/templates/blinkTopo.mat')
    
    i = 1;
    while 1
        
        if i > min([10 length(sortIndx)])
            fprintf('\t \t None found \n')
            rmComp = [];
            break
        end
        
        currComp = sortIndx(i);
        
        R1 = mean(abs(R(ring1,currComp)));
        R2 = mean(abs(R(ring2,currComp)));
        R3 = mean(abs(R(ring3,currComp)));
        R4 = mean(abs(R(ring4,currComp)));
        R5 = mean(abs(R(ring5,currComp)));
        
        if R1 > R2 && R2 > R3 && R3 > R4 && R2 > R5
            rmComp = currComp;
            fprintf('component found (%s)! \n', num2str(rmComp))
            break
        end
        
        i = i + 1;
    end
end

if freqRemoval
    fprintf('\t frequency removal ... \n')
   
    output = 'fourier';
    freqrange = [0.2 100];
    evalc('[freq, fd] = bvLL_frequencyanalysis(comp, freqrange, output, 1);');
    
    if strcmpi(gammaremoval, 'yes')
        
        fprintf('\t \t searching for components with too high gamma ... ')

        lowgammastart = find(fd.freq == 25);
        lowgammaend = find(fd.freq == 45);
        highgammastart = find(fd.freq == 55);
        highgammaend = find(fd.freq == 85);
        
        meangamma = squeeze(nanmean(nanmean(fd.powspctrm(:,:,[lowgammastart:lowgammaend, highgammastart:highgammaend])),3));
        gammacomps = find(isoutlier(meangamma));
        
        if isempty(gammacomps)
            fprintf('none found! \n')
        else
            fprintf('done! \n')
        end
        
        rmComp = [rmComp gammacomps];
        
    end
    
    if strcmpi(deltaremoval, 'yes')
        
        fprintf('\t \t searching for components with too high delta ... ')
        
        deltastart = find(fd.freq == 1);
        deltaend = find(fd.freq == 3);
        
        meandelta = ...
            squeeze(nanmean(nanmean(fd.powspctrm(:,:,deltastart:deltaend)),3));
        deltacomps = find(isoutlier(meandelta));
        
        if isempty(deltacomps)
            fprintf('none found! \n')
        else
            fprintf('done! \n')
        end
        
        rmComp = [rmComp deltacomps];
        
    end
end