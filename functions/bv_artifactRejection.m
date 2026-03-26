function [data, artifactdef, counts] = bv_artifactRejection(cfg, data)
% Automatically rejects EEG artifacts with threshold set by user in
% config-struct with helper function bvLL_artefactDetection
%
% usage with data input:
%  [data, artifactdef, counts] = bv_artifactRejection(cfg, data)
%
% usage without data-input for the analysis-pipeline:
%  [data, artifactdef, counts] = bv_artifactRejection(cfg)
%
% config structure needs to have following fields:
%     cfg.betaLim     = [ number ], threshold max beta power (default: Inf)
%     cfg.gammaLim    = [ number ], threshold max gammma power (default: Inf)
%     cfg.varLim      = [ number ], threshold max variance (default: Inf)
%     cfg.kurtLim     = [ number ], threshold max kurtosis (default: Inf)
%     cfg.invVarLim   = [ number ], threshold max inverse variance, to detect
%                       flatlining (default: Inf)
%     cfg.triallength = [ number ], triallength in seconds for which all
%                       artifacts are checked (default: 1)
%     cfg.padding     = [ number ], amount of trials padding around the
%                       artifacts (default: 1)
%     cfg.showFigures = 'yes/no', determines whether feedback will be givens
%                       through figures (default: 'no')
%
% config structure only needs to have following fields without data input:
%     cfg.saveFigures = 'yes/no', determines whether created will be save in
%                       standard PATHS.FIGURES folder
%

betaLim         = ft_getopt(cfg, 'betaLim', Inf);
gammaLim        = ft_getopt(cfg, 'gammaLim', Inf);
varLim          = ft_getopt(cfg, 'varLim', Inf);
invVarLim       = ft_getopt(cfg, 'invVarLim', Inf);
kurtLim         = ft_getopt(cfg, 'kurtLim', Inf);
flatLim         = ft_getopt(cfg, 'flatLim', Inf);
jumpLim         = ft_getopt(cfg, 'jumpLim', Inf);
triallength     = ft_getopt(cfg, 'triallength');
padding         = ft_getopt(cfg, 'padding',0);
optionsFcn      = ft_getopt(cfg, 'optionsFcn');
saveFigures     = ft_getopt(cfg, 'saveFigures', 'no');
showFigures     = ft_getopt(cfg, 'showFigures');
currSubject     = ft_getopt(cfg, 'currSubject');
inputStr        = ft_getopt(cfg, 'inputStr');
outputStr       = ft_getopt(cfg, 'outputStr');
saveData        = ft_getopt(cfg, 'saveData');
rmTrials        = ft_getopt(cfg, 'rmTrials');
cutOutputData   = ft_getopt(cfg, 'cutOutputData');
zScoreLim       = ft_getopt(cfg, 'zScoreLim');
vMaxLim         = ft_getopt(cfg, 'vMaxLim');
maxbadchans     = ft_getopt(cfg, 'maxbadchans');

cfgIn = cfg;

mp = get(0, 'MonitorPositions');
if isempty(triallength)
    redefineTrial = false;
else
    redefineTrial = true;
end

if all(isinf([betaLim gammaLim varLim invVarLim kurtLim flatLim zScoreLim vMaxLim jumpLim]))
    error('No limits given so no artefacts will be detected')
end

disp(currSubject)

if nargin < 2
    if isempty(optionsFcn)
        error('please add options function cfg.optionsFcn')
    else
        eval(optionsFcn)
    end
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    
    subjectdata.cfgs.(outputStr) = cfg;
else
    subjectdata = struct;
end

output = 'fourier';
oldData = data;

if redefineTrial
    fprintf('\t redefining triallength to %s seconds ... ', num2str(triallength))
    cfg = [];
    cfg.length = triallength;
    cfg.overlap = 0;
    evalc('data = ft_redefinetrial(cfg, oldData);');
    fprintf('done! \n')
else
    fprintf('\t trials already present, no redefining necessary \n')
end

fprintf('\t artefact calculation \n')
fprintf('\t\t frequency calculation ... ')

freqrange = [0 100];
evalc('[freq, fd] = bvLL_frequencyanalysis(data, freqrange, output);');

freqFields  = fieldnames(fd);
field2use   = freqFields{not(cellfun(@isempty, strfind(freqFields, 'spctrm')))};

fprintf('done! \n')

fprintf('\t\t artefact determination ... ')
cfg = [];
cfg.betaLim     = betaLim;
cfg.gammaLim    = gammaLim;
cfg.varLim      = varLim;
cfg.invVarLim   = invVarLim;
cfg.kurtLim     = kurtLim;
cfg.zScoreLim   = zScoreLim;
cfg.vMaxLim     = vMaxLim;
cfg.flatLim     = flatLim;
cfg.jumpLim     = jumpLim;

evalc('[artifactdef, counts] = bvLL_artefactDetection(cfg, data, freq);');
fprintf('done! \n')


if strcmpi(showFigures, 'yes')
    
    if exist('findCoords', 'file')
        [xScreenLength, yScreenLength] = findCoords;
    else
        xScreenLength = 1;
        yScreenLength = 1;
    end
    
    fprintf('\t creating and plotting figures for artefacts \n')
    fprintf('\t\t creating frequency spectrum plot ...')
    
    figure; semilogy(freq.freq, squeeze(nanmean(fd.(field2use)))', 'LineWidth', 2)
    legend(data.label)
    set(gca, 'XLim', [0 50])
    set(gca, 'YLim', [-4 Inf])
    title(strrep(currSubject,'_', ' '))
    fprintf('done! \n')
    
    if strcmpi(saveFigures, 'yes')
        fprintf('\t\t\t saving ... ')
        set(gcf, 'Position', mp(size(mp,1),:));
        saveas(gcf, [PATHS.FIGURES filesep currSubject '_' inputStr '_freqDirty.png'])
        fprintf('done! \n')
        close all
    end
    % figure;
    fprintf('\t\t creating scrollplot with artefacts in red ... ')
    cfg = [];
    cfg.badPartsMatrix  = artifactdef.badPartsMatrix;
    cfg.horzLim         = 'full';
    cfg.scroll          = 0;
    cfg.visible         = 'on';
    cfg.triallength     = triallength;
    scrollPlot          = scrollPlotData(cfg, data);
    
    fprintf('done! \n')
    
    if strcmpi(saveFigures,'yes')
        fprintf('\t\t\t saving ... ')
        saveas(gcf, [PATHS.FIGURES filesep currSubject '_' inputStr '_dataDirty.png'])
        fprintf('done! \n')
        close all
    end
end

badTrialsPerChannel = hist(artifactdef.badPartsMatrix(:,2),1:length(data.label));
pBadTrials = badTrialsPerChannel / length(data.trial);
chans2remove = data.label(pBadTrials > 0.39);
flatliners = data.label((sum(artifactdef.flatline.levels > flatLim,2) ./ length(data.trial)>0.4));

if isfield(subjectdata, 'flatliners')
    subjectdata.flatliners = unique(cat(1,subjectdata.flatliners, flatliners));
else
    subjectdata.flatliners = flatliners;
end

if ~length(chans2remove) == 0
    if isfield(subjectdata, 'rmChannels')
        allRmChannels = unique([chans2remove; subjectdata.rmChannels]);
        if length(allRmChannels) > maxbadchans
            fprintf(['\t too many bad channels (' repmat('%s ', 1, length(allRmChannels)) '), removing ... '], allRmChannels{:})
            removingSubjects([], currSubject, 'channelremoval - too many channels removed')
            return
        end
    else
        if length(chans2remove) > maxbadchans
            fprintf(['\t too many bad channels (' repmat('%s ', 1, length(chans2remove)) '), removing ... '], chans2remove{:})
            removingSubjects([], currSubject, 'channelremoval - too many channels removed')
            return
        end
    end
    
    fprintf(['\t channels to remove and interpolate: ' repmat('%s ', 1, length(chans2remove)) '... \n'], chans2remove{:})
    
    if isfield(subjectdata, 'rmChannels')
        subjectdata.rmChannels = reshape(subjectdata.rmChannels,length(subjectdata.rmChannels), 1);
        subjectdata.rmChannels = cat(1, subjectdata.rmChannels, chans2remove);
        subjectdata.rmChannels = unique(subjectdata.rmChannels);
    else
        subjectdata.rmChannels = chans2remove;
    end
    
    
    rmChannelIndx = ismember(data.label, chans2remove);
    
    if sum(rmChannelIndx) == length(data.label)
        removingSubjects([], currSubject, 'No artefact free channels')
        return
    end
    
    cfg = [];
    cfg.layout = 'EEG1010';
    cfg.channel = 'all';
    cfg.feedback = 'no';
    cfg.skipcomnt = 'yes';
    cfg.skipscale = 'yes';
    evalc('lay = ft_prepare_layout(cfg, data);');
    
    cfg = [];
    cfg.method          = 'distance';
    cfg.neighbourdist   = 0.25;
    cfg.template        = 'EEG1010';
    cfg.layout          = lay;
    cfg.channel         = 'all';
    cfg.feedback        = 'no';
    cfg.skipcomnt       = 'yes';
    cfg.skipscale       = 'yes';
    evalc('neighbours = ft_prepare_neighbours(cfg, data);');
    
    cfg = [];
    cfg.badchannel = chans2remove;
    cfg.method = 'weighted';
    cfg.neighbours = neighbours;
    cfg.channel = 'all';
    cfg.layout = lay;
    
    if strcmpi(cutOutputData, 'yes')
        
        evalc('data = ft_channelrepair(cfg, data);');
        
        fprintf('\t recalculating artefacts with channels interpolated \n')
        
        fprintf('\t\t frequency calculation ... ')
        evalc('freq = bvLL_frequencyanalysis(data, freqrange,output);');
        fprintf('done! \n')
        
        fprintf('\t\t artefact determination ... ');
        cfg = [];
        cfg.betaLim     = betaLim;
        cfg.gammaLim    = gammaLim;
        cfg.varLim      = varLim;
        cfg.invVarLim   = invVarLim;
        cfg.kurtLim     = kurtLim;
        cfg.zScoreLim   = zScoreLim;
        cfg.vMaxLim     = vMaxLim;
        cfg.jumpLim     = jumpLim;
        
        evalc('[artifactdef, counts] = bvLL_artefactDetection(cfg, data, freq);');
        fprintf('done! \n');
    else
        
        evalc('data = ft_channelrepair(cfg, oldData);');
        
        if strcmpi(showFigures, 'yes');
            fprintf('\t showing cleaned frequency spectrum ... ')
            
            if redefineTrial
                cfg = [];
                cfg.length  = triallength;
                cfg.overlap = 0;
                evalc('dataCut = ft_redefinetrial(cfg, data);');
            else
                dataCut = data;
            end
            
            evalc('[freq, fd] = bvLL_frequencyanalysis(dataCut, freqrange,output);');
            
            figure; semilogy(freq.freq, squeeze(mean(fd.(field2use)))', 'LineWidth', 2)
            legend(data.label)
            set(gca, 'YLim', [-4 Inf]);
            set(gca, 'XLim', [0 50]);
            set(gcf, 'Position', mp(size(mp,1),:));
            fprintf('done! \n')
            drawnow;
        end
    end
else
    fprintf('\t No channels to REMOVE! \n')
    
    if ~strcmpi(cutOutputData, 'yes')
        data = oldData;
    end
    
end

if strcmpi(rmTrials, 'yes')
    
    %     subjectdata.goodTrials = artifactdef.goodTrials';
    %     subjectdata.badTrials = artifactdef.badTrials;
    
    artifactdef.badTrials = unique([artifactdef.badTrials ...
        artifactdef.badTrials - (padding * triallength) ...
        artifactdef.badTrials + (padding * triallength)]);
    
    percentageBad = (length(artifactdef.badTrials) ./ length(data.trial)) ...
        * 100;
    
    artifactdef.goodTrials = find(ismember(1:length(data.trial), ...
        artifactdef.badTrials)==0);
    
    fprintf('\t removing artefactridden trials (%1.0f%%)... ', ...
        percentageBad)
    cfg = [];
    cfg.trials = artifactdef.goodTrials;
    evalc('data = ft_selectdata(cfg, data);');
    fprintf('done! \n')
    
    subjectdata.cleanTRL = [data.sampleinfo zeros(length(data.trialinfo), 1) data.trialinfo];
    
    if strcmpi(showFigures, 'yes')
        fprintf('\t creating and plotting cleaned figures \n')
        
        fprintf('\t\t creating clean frequency spectrum plot ... ')
        evalc('[freq, fd] = bvLL_frequencyanalysis(data, freqrange,output);');
        
        figure; semilogy(freq.freq, squeeze(mean(fd.(field2use)))', ...
            'LineWidth', 2)
        legend(data.label)
        set(gca, 'YLim', [-4 Inf])
        set(gca, 'XLim', [0 50])
        title(strrep(currSubject,'_', ' '))
        fprintf('done! \n')
        
        if strcmpi(saveFigures, 'yes')
            fprintf('\t\t\t saving ... ')
            set(gcf, 'Position', mp(size(mp,1),:));
            saveas(gcf, [PATHS.FIGURES filesep currSubject '_' inputStr ...
                '_freqClean.png'])
            fprintf('done! \n')
            close all
        end
        
        fprintf('\t\t creating clean scrollplot ... ');
        cfg = [];
        cfg.betaLim     = betaLim;
        cfg.gammaLim    = gammaLim;
        cfg.varLim      = varLim;
        cfg.invVarLim   = invVarLim;
        cfg.kurtLim     = kurtLim;
        cfg.zScoreLim   = zScoreLim;
        cfg.vMaxLim     = vMaxLim;
        
        evalc('[artifactdef, counts] = bvLL_artefactDetection(cfg, data, freq);');
        
        % figure;
        %         addpath('~/git/eeg-graphmetrics-processing/figures/')
        cfg = [];
        cfg.badPartsMatrix  = artifactdef.badPartsMatrix;
        cfg.horzLim         = 'full';
        cfg.scroll          = 0;
        cfg.visible         = 'on';
        cfg.triallength     = triallength;
        scrollPlot          = scrollPlotData(cfg, data);
        fprintf('done! \n')
        
        if strcmpi(saveFigures, 'yes')
            fprintf('\t\t\t saving ... ')
            set(gcf, 'Position', mp(size(mp,1),:));
            saveas(gcf, [PATHS.FIGURES filesep currSubject '_' inputStr ...
                '_dataClean.png'])
            fprintf('done! \n')
            close all
        end
        
    end
    
    if strcmpi(saveData, 'yes')
        subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata)
        
        bv_saveData(subjectdata, data, outputStr);
    end
else
    if strcmpi(saveData, 'yes')
        
        subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata)
        
        bv_saveData(subjectdata, data, outputStr);
        
    end
end



fprintf('\t all done! \n')

close all
clear subjectdata
