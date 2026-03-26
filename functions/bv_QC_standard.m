function data = bv_QC_standard( cfg, data )

% general options
subdirectory        = ft_getopt(cfg, 'subdirectory');
RAWDir              = ft_getopt(cfg, 'RAWDir', 'RAW');
overwrite           = ft_getopt(cfg, 'overwrite', 1);
analyses            = ft_getopt(cfg, 'analyses', 'all');
triallength         = ft_getopt(cfg, 'triallength', 1);
saveAnalysisSteps   = ft_getopt(cfg, 'saveAnalysisSteps');
startSubject        = ft_getopt(cfg, 'startSubject', 1);
endSubject          = ft_getopt(cfg, 'endSubject', 'last');
createFigures       = ft_getopt(cfg, 'createFigures');
subjectsDir         = ft_getopt(cfg, 'subjectsDir', 'Subjects');
dataStr             = ft_getopt(cfg, 'dataStr', 'data');
artefactdefStr      = ft_getopt(cfg, 'artefactdefStr', 'artefactdef');
freqStr             = ft_getopt(cfg, 'freqStr', 'freq');
compStr             = ft_getopt(cfg, 'compStr', 'comp');
dataType            = ft_getopt(cfg, 'dataType');
trialfun            = ft_getopt(cfg, 'trialfun');
optionsFcn          = ft_getopt(cfg, 'optionsFcn');

% options for quality control
QCDir       = ft_getopt(cfg, 'QCDir', 'QualityControl');

% get options for preprocessing from cfg file
preprocessing 	= ft_getopt(cfg, 'preprocessing');
hpfilter    	= ft_getopt(cfg, 'hpfilter', 1);
hpfreq      	= ft_getopt(cfg, 'hpfreq', 2);
bsfilter    	= ft_getopt(cfg, 'bsfilter', 1);
bsfreq      	= ft_getopt(cfg, 'bsfreq', [48 52; 98 102]);
resample    	= ft_getopt(cfg, 'resampling', 1);
resamplefs  	= ft_getopt(cfg, 'resamplefs', 512);
trigger     	= ft_getopt(cfg, 'trigger');
rmBadChannelsPreprocess = ft_getopt(cfg, 'rmBadChannelsPreprocess');

% Get options for frequency analysis
frequencyanalysis 	= ft_getopt(cfg, 'frequencyanalysis');
freqrange   		= ft_getopt(cfg, 'freqrange', [1 100]);

% removing components
removeComponents    = ft_getopt(cfg, 'removeComponents');

% Get options for artefact detection from cfg-file
artefactanalysis 	= ft_getopt(cfg, 'artefactanalysis');
betaLim     		= ft_getopt(cfg, 'betaLim', 20);
gammaLim   			= ft_getopt(cfg, 'gammaLim', 20);
varLim      		= ft_getopt(cfg, 'varLim', 1500);
invVarLim   		= ft_getopt(cfg, 'invVarLim', 0.05);
kurtLim     		= ft_getopt(cfg, 'kurtLim', 10);
rangeLim    		= ft_getopt(cfg, 'rangeLim', 250);

% options for detecting bad channels
detectBadChannels 	= ft_getopt(cfg, 'detectBadChannels');
pBadTrials      	= ft_getopt(cfg, 'pBadTrials', 50);
rmBadChannels   	= ft_getopt(cfg, 'rmBadChannels', 'no');

% options for figures
createFigures	= ft_getopt(cfg, 'createFigures');
showFigures 	= ft_getopt(cfg, 'showFigures', 'off');
saveFigures 	= ft_getopt(cfg, 'saveFigures', 'on');

% options if data is given as input
subjectName = ft_getopt(cfg, 'subjectName');
hdrFile     = ft_getopt(cfg, 'hdrfile');
dataSet     = ft_getopt(cfg, 'dataSet');

% options for counting clean trials
countGoodTrials = ft_getopt(cfg, 'countGoodTrials');
triallength2use = ft_getopt( cfg, 'triallength2use', 'default');

% detemine analyses to be done
analyses = {};
if strcmpi(preprocessing, 'yes')
    analyses = cat(1,analyses, 'preprocessRaw');
end
if strcmpi(removeComponents, 'yes')
    analyses = cat(1,analyses, 'removeComponents');
end
if strcmpi(frequencyanalysis, 'yes')
    analyses = cat(1,analyses, 'freqAnalysis');
end
if strcmpi(artefactanalysis, 'yes')
    analyses = cat(1,analyses, 'artefactDetection');
end
if strcmpi(detectBadChannels, 'yes')
    analyses = cat(1,analyses, 'detectBadChannels');
end
if strcmpi(createFigures, 'yes')
    analyses = cat(1,analyses, 'createFigures');
end
if strcmpi(countGoodTrials, 'yes')
    analyses = cat(1,analyses, 'countGoodTrials');
end

if strcmpi(rmBadChannelsPreprocess, 'yes')
    rmBadChannelsPreprocess = 1;
elseif strcmpi(rmBadChannelsPreprocess, 'no')
    rmBadChannelsPreprocess = 0;
end

if isempty(analyses)
    error('no analyses set')
end

% rename different options
if strcmpi(rmBadChannels, 'yes')
    rmBadChannels = true;
else
    rmBadChannels = false;
end

if strcmpi(overwrite, 'yes')
    overwrite = 1;
else
    overwrite = 0;
end


dataInput = 0;
if nargin == 2
    if isempty(subjectName)
        error('No subjectName given, while using your own data as input')
    end
    dataInput = 1;
    analyses( ismember( analyses, 'preprocessRaw' ) ) = [];
    
    if sum(ismember(analyses, 'artefactDetection')) == 0
        analyses = cat(2, 'artefactDetection', analyses);
    end
    
    if sum(ismember(analyses, 'freqAnalysis')) == 0
        analyses = cat(2, 'freqAnalysis', analyses);
    end
    
    startSubject = 1;
    endSubject = 1;
    
else
    
    eval(optionsFcn)
    PATHS.OUTPUT = PATHS.QCDir;
    
    bdfFiles = dir([PATHS.RAWS filesep '*' dataType ]);
    bdfNames = {bdfFiles.name};
    
    if ischar(startSubject)
        startSubject = find(~cellfun(@isempty, strfind(bdfNames, startSubject)));
    end
    if ischar(endSubject)
        if strcmp(endSubject, 'last')
            endSubject = length(bdfNames);
        else
            endSubject = find(~cellfun(@isempty, strfind(bdfNames, endSubject)));
        end
    end
    
end


summaryFigureFolder = [PATHS.OUTPUT filesep 'figures'];
if ~exist(summaryFigureFolder, 'dir')
    mkdir(summaryFigureFolder)
end

if rmBadChannels
    cleanedString = '_cleaned';
else
    cleanedString = [];
end

for iRaw = startSubject:endSubject
    tic
    
    personalAnalyses = analyses;
    
    if ~dataInput
        currFilename = bdfNames{iRaw};
        splitFilename = strsplit(currFilename, '_');
        subjectName = splitFilename{1};
        headerfile = [PATHS.RAWS filesep currFilename];
        
        disp(subjectName)
        subjectFolderName = dir([PATHS.SUBJECTS filesep '*' subjectName '*']);
        
        personalOutputFolder = [PATHS.OUTPUT filesep subjectName filesep subdirectory];
        subjectRootFolder = [PATHS.SUBJECTS filesep subjectName ];
        dataFilename = [subjectName '_' dataStr '.mat'];
        artefactFilename = [subjectName '_' artefactdefStr '.mat'];
        freqFilename = [subjectName '_' freqStr '.mat'];
        compFilename = [subjectName '_' compStr '.mat'];
        
        scrollPlotName = [summaryFigureFolder filesep subjectName '_scrollPlot' cleanedString '.png'];
        freqPlotName = [summaryFigureFolder filesep subjectName '_freqPlot' cleanedString '.png'];
        countsBarName = [summaryFigureFolder filesep subjectName '_countsBar' cleanedString '.png'];
        pBadBarName = [summaryFigureFolder filesep subjectName '_pBadBar' cleanedString '.png'];
        
        if createFigures
            if exist(scrollPlotName, 'file') && exist(freqPlotName, 'file') && exist(countsBarName, 'file') && exist(pBadBarName, 'file') && ~overwrite
                fprintf('\t Figures already found, not doing again \n')
                personalAnalyses(ismember(personalAnalyses, 'createFigures')) = [];
            end
        end
        
        try
            load([subjectRootFolder filesep 'Subject.mat'])
        catch
            fprintf('\t Subject.mat file not found, creating a new one \n ')
        end
        
        if exist([personalOutputFolder filesep dataFilename], 'file')
            load([personalOutputFolder filesep dataFilename])
            fprintf(' \t Preprocessing RAW data \n')
            fprintf(' \t \t previous data file found and loaded \n')
            
            if length(data.trial{1}) ~= data.fsample*triallength
                fprintf(['\t \t Redefining triallength to ' num2str( triallength ) ' seconds, ... '])
                
                hdrFile = currFilename;
                dataSet = currFilename;
                
                %                 cfg = [];
                %                 cfg.length = triallength;
                %                 cfg.overlap = 0;
                %                 evalc('data = ft_redefinetrial(cfg, data);');
                %                 fprintf('done \n')
            end
            
            if ~overwrite
                personalAnalyses( ismember( personalAnalyses, 'preprocessRaw' ) ) = [];
            end
        end
        
        if exist([personalOutputFolder filesep freqFilename], 'file')
            load([personalOutputFolder filesep freqFilename])
            fprintf('\t Doing frequency analysis \n')
            fprintf(' \t \t previous freq file found and loaded \n')
            if ~overwrite
                personalAnalyses( ismember( personalAnalyses, 'freqAnalysis' ) ) = [];
            end
        end
        
        if exist([personalOutputFolder filesep artefactFilename], 'file')
            load([personalOutputFolder filesep artefactFilename])
            fprintf('\t Artefact detection \n')
            fprintf(' \t \t previous artefactdef file found and loaded \n')
            if ~overwrite
                personalAnalyses( ismember( personalAnalyses, 'artefactDetection' ) ) = [];
            end
        end
    else
        PATHS.OUTPUT    = pwd;
        disp(subjectName)
        fprintf('\t Data input detected, using this data \n')
        fprintf(['\t \t Redefining triallength to ' num2str( triallength ) ' seconds, ... '])
        
        cfg = [];
        cfg.Fs = data.fsample;
        
        if isfield(data.hdr, 'orig')
            hdrFile = data.hdr.orig.FileName;
            dataSet = data.hdr.orig.FileName;
        end
        
        cfg.headerfile = hdrFile;
        cfg.dataset = dataSet;
        cfg.trialfun = 'trialfun_testRetest_QC';
        cfg = ft_definetrial(cfg);
        evalc('data = ft_redefinetrial(cfg, data);');
        
        cfg = [];
        cfg.length = triallength;
        cfg.overlap = 0;
        evalc('data = ft_redefinetrial(cfg, data);');
        fprintf('done \n')
    end
    
    for iAnalysis = 1:length(personalAnalyses)
        switch personalAnalyses{iAnalysis}
            
            case 'preprocessRaw'
                fprintf('\t Preprocessing RAW data \n')
                
                channels = 'EEG';
                if rmBadChannelsPreprocess
                    if isfield(subjectdata, 'removedchannels')
                        removedChannels = strcat('-', subjectdata.removedchannels);
                        channels = cat(2,channels,removedChannels');
                    else
                        error('rmBadChannels selected, but no removedchannels field detected in the subject.mat file')
                    end
                end
                
                % get options for preprocessing from cfg file
                cfg.hpfilter    = hpfilter;
                cfg.hpfreq      = hpfreq;
                cfg.bsfilter    = bsfilter;
                cfg.bsfreq      = bsfreq;
                cfg.resample    = resample;
                cfg.resamplefs  = resamplefs;
                cfg.headerfile  = headerfile;
                cfg.dataset     = dataset;
                cfg.channels    = channels;
                cfg.trigger     = trigger;
                cfg.trialfun    = trialfun;
                
                data = bvLL_preprocessing(cfg);
                
                if strcmpi(saveAnalysisSteps, 'yes')
                    if ~exist(personalOutputFolder,'dir')
                        mkdir(personalOutputFolder)
                    end
                    fprintf('\t \t saving preprocessed data to %s ... ', dataFilename)
                    save([personalOutputFolder filesep dataFilename], 'data');
                    fprintf('done \n')
                end
                
                fprintf(['\t \t Redefining triallength to ' num2str( triallength ) ' seconds, ... '])
                cfg = [];
                cfg.length = triallength;
                cfg.overlap = 0;
                evalc('data = ft_redefinetrial(cfg, data);');
                fprintf('done \n')
                
                fprintf('\t \t preprocessing RAW data done! \n')
                
            case 'removeComponents'
                fprintf('\t detecting and removing components \n')
                fprintf('\t \t detecting ... ')
                cfg = [];
                cfg.method = 'runica';
                evalc('comp = ft_componentanalysis(cfg, data);');
                fprintf('done \n')
                
%                 cfg = [];
%                 cfg.layout = 'EEG1010';
%                 cfg.viewmode = 'component';
% %                 cfg.channel = 'all';
% %                 cfg.ylim      = [-0.005 0.005];
%                 cfg.interactive = 'no';
%                 evalc('ft_databrowser(cfg,comp);');
%                 
%                 cfg = [];
%                 cfg.component = 1:30; % specify the component(s) that should be plotted
%                 cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
%                 cfg.comment   = 'no';
%                 cfg.compscale = 'local';
%                 cfg.interactive = 'no';
%                 figure();
%                 evalc('ft_topoplotIC(cfg, comp);');
%     
%                 fprintf('\t \t component removal')
                
%                 removComps = input(...
%                     'type the components that should be removed in a vector? or type ''delete'' to remove subject based on ICA data \n');
%                 

                fprintf('\t \t rejecting ... ')
                cfg = [];
                cfg.component = 1;
                evalc('data = ft_rejectcomponent(cfg, comp, data);');
                fprintf('done \n')
                
                if strcmpi(saveAnalysisSteps, 'yes')
                    fprintf('\t \t saving component data to %s ... ', compFilename)
                    save([personalOutputFolder filesep compFilename], 'comp');
                    fprintf('done \n')
                end
                
            case 'freqAnalysis'
                fprintf('\t Doing frequency analysis \n')
                
                
                
                
                freq = bvLL_frequencyanalysis(data, freqrange);
                
                if strcmpi(saveAnalysisSteps, 'yes')
                    fprintf('\t \t saving preprocessed data to %s ... ', freqFilename)
                    save([personalOutputFolder filesep freqFilename], 'freq');
                    fprintf('done \n')
                end
                
                fprintf('\t \t frequency analysis done! \n')
                
                
            case 'artefactDetection'
                fprintf('\t Artefact detection \n')
                % Artefact detection
                
                if ~exist('data', 'var')
                    error('Preprocessing not turned on and previous data file not found')
                end
                
                %                 if length(data.trial{1}) ~= data.fsample * triallength
                %                     cfg = [];
                %                     cfg.length = triallength;
                %                     cfg.overlap = 0;
                %                     evalc('data = ft_redefinetrial(cfg, data);');
                %                 end
                
                cfg = [];
                cfg.betaLim     = betaLim;
                cfg.gammaLim    = gammaLim;
                cfg.varLim      = varLim;
                cfg.invVarLim   = invVarLim;
                cfg.kurtLim     = kurtLim;
                cfg.rangeLim    = rangeLim;
                [artefactdef, counts] = bvLL_artefactDetection(cfg, data, freq);
                
                if strcmpi(saveAnalysisSteps, 'yes')
                    fprintf('\t \t saving artefact definition to %s ... ', artefactFilename)
                    save([personalOutputFolder filesep artefactFilename], 'artefactdef');
                    fprintf('done \n')
                end
                
                fprintf('\t \t Artifact analysis done! \n')
            case 'detectBadChannels'
                
                % options for bad trial detection
                fprintf('\t Detecting and saving bad channels ... \n')
                
                subjectdata.removedchannels = data.label(artefactdef.pBadTrialsPerChannel > pBadTrials);
                
                fprintf(['\t \t storing the following channels to be removed: '...
                    repmat('%s ', 1, length(subjectdata.removedchannels)) '\n'], subjectdata.removedchannels{:})
                
                if ~exist(subjectRootFolder, 'dir')
                    mkdir(subjectRootFolder)
                end
                
                fprintf('\t \t saving bad channels to Subject.mat file...')
                save([subjectRootFolder filesep 'Subject.mat'], 'subjectdata');
                fprintf('done \n')
                
                fprintf('\t \t detecting and saving bad channels done \n')
                
                if rmBadChannels
                    
                    fprintf([' \t removing the following channels: ' repmat('%s ', 1, length(subjectdata.removedchannels))], subjectdata.removedchannels{:})
                    removedChannels = strcat('-', subjectdata.removedchannels);
                    channelString = cat(2,'all',removedChannels');
                    
                    cfg = [];
                    cfg.channel = channelString;
                    evalc('data = ft_selectdata(cfg, data);');
                    
                    fprintf('done \n ')
                    
                    fprintf(' \t \t starting artefact rejection without removed channels \n ');
                    
                    fprintf(['\t \t Redefining triallength to ' num2str( triallength ) ' seconds, ... '])
                    cfg = [];
                    cfg.length = triallength;
                    cfg.overlap = 0;
                    evalc('data = ft_redefinetrial(cfg, data);');
                    fprintf('done \n')
                    
                    freq = bvLL_frequencyanalysis(data, freqrange);
                    
                    cfg = [];
                    cfg.betaLim     = betaLim;
                    cfg.gammaLim    = gammaLim;
                    cfg.varLim      = varLim;
                    cfg.invVarLim   = invVarLim;
                    cfg.kurtLim     = kurtLim;
                    [artefactdef, counts] = bvLL_artefactDetection(cfg, data, freq);
                    fprintf(' \t \t artefact rejection without removed channels done \n')
                    
                end
                
            case 'createFigures'
                addpath([PATHS.SUBFUNCTIONS filesep 'figures'])
                
                fprintf('\t Creating figures \n')
                
                fprintf('\t \t creating scrollPlot ... ')
                cfg = [];
                cfg.badPartsMatrix  = artefactdef.badPartsMatrix;
                cfg.horzLim         = 'full';
                cfg.triallength     = 1;
                cfg.scroll          = 0;
                cfg.visible         = showFigures;
                cfg.triallength     = triallength;
                scrollPlot          = scrollPlotData(cfg, data);
                fprintf('done \n')
                
                % frequency spectrum
                fprintf('\t \t creating frequency spectrum plot ... ')
                
                % sort channels based on average power
                [~, sortIdx] = sort(squeeze(mean(mean(freq.powspctrm(:,:,:),1),3)), 'descend');
                % creating frequecy power spectrum
                freqSpectrum = figure('Visible', showFigures);
                plot(freq.freq, squeeze(mean(freq.powspctrm(:,sortIdx,:),1)))
                title([subjectName ': frequency power spectrum']);
                legend(freq.label(sortIdx))
                set(gca, 'FontSize', 20, 'YLim', [0 max(squeeze(median(mean(freq.powspctrm,1),2)))])
                set(gcf, 'Position', get(0,'Screensize'))
                fprintf('done \n')
                
                % barplots
                % amount of trials per limit per channel
                fprintf('\t \t creating barplot with counts of bad trials ... ')
                countsBar = figure('Visible', showFigures);
                bar(artefactdef.allCounts,'stacked');
                legend({'Variance', '1/Variance', 'Kurtosis', 'BetaPower', 'GammaPower'})
                set(gca, 'XTick', 1:size(artefactdef.kurtLevels,1),'XTickLabel', data.label, 'FontSize', 20)
                set(gcf, 'Position', get(0,'Screensize'))
                fprintf('done \n')
                
                % percentage of trials bad
                fprintf('\t \t creating barplot with percentage of bad trials ... ')
                pBadBar = figure('Visible', showFigures);
                superbar(artefactdef.pBadTrialsPerChannel)
                set(gca, 'XTick', 1:size(artefactdef.kurtLevels,1),'XTickLabel', data.label, 'FontSize', 20)
                ylabel('% bad trials')
                xlabel('Channel name')
                title(['Percentage bad trials per channel for subject ' subjectName])
                set(gcf, 'Position', get(0,'Screensize'))
                fprintf('done \n')
                
                
                if strcmpi(saveFigures, 'yes')
                    fprintf('\t \t saving figures ... ')
                    
                    print(scrollPlot, [summaryFigureFolder filesep subjectName '_scrollPlot' cleanedString '.png'] , '-dpng')
                    fprintf('1, ')
                    print(freqSpectrum, [summaryFigureFolder filesep subjectName '_freqPlot' cleanedString '.png'] , '-dpng')
                    fprintf('2, ')
                    print(countsBar, [summaryFigureFolder filesep subjectName '_countsBar' cleanedString '.png'] , '-dpng')
                    fprintf('3, ')
                    print(pBadBar, [summaryFigureFolder filesep subjectName '_pBadBar' cleanedString '.png'] , '-dpng')
                    fprintf('4! ')
                    
                    fprintf('done \n ')
                end
                
            case 'countGoodTrials'
                
                fprintf('\t Counting good trials with a length of %s seconds \n', num2str(triallength2use))
                while 1
                    
                    if rmBadChannels
                        cleanedString = '_cleaned';
                    else
                        cleanedString = [];
                    end
                    
                    if strcmp(triallength2use, 'default')
                        triallength2use = length(data.trial{1}) ./ data.fsample;
                    end
                    
                    if ~isempty(artefactdef.goodTrials)
                        
                        conditionSwitch = [find( diff( data.trialinfo ) ~= 0); length(data.trialinfo)];
                        conditions = [conditionSwitch data.trialinfo( conditionSwitch')];
                        
                        goodSampleinfo = data.sampleinfo(artefactdef.goodTrials, :);
                        
                        vGoodSampleinfo = [];
                        for i = 1: size(goodSampleinfo, 1)
                            vGoodSampleinfo = [vGoodSampleinfo goodSampleinfo(i,1):goodSampleinfo(i,2)];
                        end
                        
                        diffBetweenTrials = diff(vGoodSampleinfo);
                        badTrialsIndx = find(diffBetweenTrials > 1);
                        lnghtConseqSamples = diff([0 badTrialsIndx]);
                        
                        trlsWthGoodLength = find(lnghtConseqSamples >= triallength2use * data.fsample);
                        
                        trlStarts = [];
                        trlEnds = [];
                        for i = 1:length(trlsWthGoodLength)
                            
                            trlStart = artefactdef.goodTrials(sum(lnghtConseqSamples(1:(trlsWthGoodLength(i)-1))) ./ length(data.trial{1}) + 1);
                            trlEnd = artefactdef.goodTrials(sum(lnghtConseqSamples(1:trlsWthGoodLength(i))) ./ length(data.trial{1}));
                            trlLength = length(trlStart:trlEnd);
                            noTrials = floor(((trlLength*length(data.trial{1}))./ triallength2use) ./ data.fsample);
                            trialVector = 0:1:noTrials-1;
                            currTrlStarts = trlStart + (trialVector.*(triallength2use/length(data.trial{1})));
                            trlStarts = [trlStarts; currTrlStarts'];
                            currTrlEnds = currTrlStarts + triallength2use/ (length(data.trial{1})./ data.fsample);
                            trlEnds = [trlEnds; currTrlEnds'];
                            
                        end
                        
                        trlInfo = [trlStarts trlEnds zeros(length(trlStarts),1)];
                        
                        for i = 1:size(trlInfo,1)
                            conditions2use = conditions(conditions(:,1) >= trlInfo(i,1),:);
                            trlInfo(i,3) = conditions2use(1,2);
                        end
                        
                        if isempty(trlInfo)
                            trials2Use = 0;
                            
                            if rmBadChannels
                                subjectdata.useableTrials.withoutBadChannels.total = trials2Use;
                            else
                                subjectdata.useableTrials.withBadChannels.total = trials2Use;
                            end
                            
                            conditionInfo = unique(data.trialinfo);
                            fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
                            for i = 1:length(conditionInfo)
                                fieldname = ['condition' num2str(conditionInfo(i)) cleanedString];
                                
                                if rmBadChannels
                                    subjectdata.useableTrials.withoutBadChannels.(fieldname) = 0;
                                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withoutBadChannels.(fieldname)), num2str(conditionInfo(i)))
                                else
                                    subjectdata.useableTrials.withBadChannels.(fieldname) = 0;
                                    fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withBadChannels.(fieldname)), num2str(conditionInfo(i)))
                                end
                                
                            end
                            break
                        end
                        
                        [a, b] = hist(trlInfo(:,3), unique(conditions(:,2)));
                        
                        trials2Use = size(trlInfo, 1);
                        
                        if rmBadChannels
                            subjectdata.useableTrials.withoutBadChannels.total = trials2Use;
                        else
                            subjectdata.useableTrials.withBadChannels.total = trials2Use;
                        end
                        
                        fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
                        for i = 1:length(a)
                            fieldname = ['condition' num2str(b(i)) cleanedString];
                            
                            if rmBadChannels
                                subjectdata.useableTrials.withoutBadChannels.(fieldname) = a(i);
                                fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withoutBadChannels.(fieldname)), num2str(b(i)))
                            else
                                subjectdata.useableTrials.withBadChannels.(fieldname) = a(i);
                                fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withBadChannels.(fieldname)), num2str(b(i)))
                            end
                            
                        end
                        
                    else
                        
                        trials2Use = 0;
                        conditionInfo = unique(data.trialinfo);
                        fprintf('\t \t %s clean trials found of which: \n', num2str(trials2Use))
                        
                        if rmBadChannels
                            subjectdata.useableTrials.withoutBadChannels.total = trials2Use;
                        else
                            subjectdata.useableTrials.withBadChannels.total = trials2Use;
                        end
                        
                        for i = 1:length(conditionInfo)
                            fieldname = ['condition' num2str(conditionInfo(i)) cleanedString];
                            
                            if rmBadChannels
                                subjectdata.useableTrials.withoutBadChannels.(fieldname) = 0;
                                fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withoutBadChannels.(fieldname)), num2str(conditionInfo(i)))
                            else
                                subjectdata.useableTrials.withBadChannels.(fieldname) = 0;
                                fprintf('\t \t \t %s in condition %s \n', num2str(subjectdata.useableTrials.withBadChannels.(fieldname)), num2str(conditionInfo(i)))
                            end
                            
                        end
                    end
                    break
                    
                end
                
                fprintf('\t \t saving good trials to Subject.mat file...')
                save([subjectRootFolder filesep 'Subject.mat'], 'subjectdata');
                fprintf('done \n')
                
                
        end
    end
    
    timeElapsed = toc;
    fprintf('\t Quality control done in %f seconds! \n', timeElapsed)
    clear data artefactdef counts
    close all
    
end
