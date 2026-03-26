function createArtefactFigures_testRetest(cfg)

saveFigures     = ft_getopt(cfg, 'saveFigures', 'on');
triallength     = ft_getopt(cfg, 'triallength', 1);
showFigures     = ft_getopt(cfg, 'showFigures', 'off');
startSubject    = ft_getopt(cfg, 'startSubject', 1);
endSubject      = ft_getopt(cfg, 'endSubject', 'end');
optionsFcn      = ft_getopt(cfg, 'optionsFcn');
redefineTrial   = ft_getopt(cfg, 'redefineTrial');

eval(optionsFcn)
cleanedString = [];

summaryFigureFolder = [PATHS.SUBJECTS filesep 'figures'];
if ~exist(summaryFigureFolder, 'dir')
    mkdir(summaryFigureFolder)
end

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
    
    fprintf('\t Creating figures \n')
    
    if redefineTrial
        if length(data.trial{1}) ~= data.fsample * triallength
            cfg = [];
            cfg.length = triallength;
            cfg.overlap = 0;
            evalc('data = ft_redefinetrial(cfg, data);');
        end
    end
    
    fprintf('\t \t creating scrollPlot ... ')
    cfg = [];
    cfg.badPartsMatrix  = artefactdef.badPartsMatrix;
    cfg.horzLim         = 'full';
    cfg.scroll          = 0;
    cfg.visible         = 'off';
    cfg.triallength     = length(data.trial{1}) ./ data.fsample;
    scrollPlot          = scrollPlotData(cfg, data);
    fprintf('done \n')
    
    % frequency spectrum
    fprintf('\t \t creating frequency spectrum plot ... ')
    
    % sort channels based on average power
    [~, sortIdx] = sort(squeeze(mean(mean(freq.powspctrm(:,:,:),1),3)), 'descend');
    % creating frequecy power spectrum
    freqSpectrum = figure('Visible', showFigures);
    plot(freq.freq, squeeze(mean(freq.powspctrm(:,sortIdx,:),1)))
    title([subjectNameSession ': frequency power spectrum']);
    legend(freq.label(sortIdx))
    set(gca, 'FontSize', 20, 'YLim', [0 max(squeeze(median(mean(freq.powspctrm,1),2)))])
    set(gcf, 'Position', get(0,'Screensize'))
    fprintf('done \n')
    
    % barplots
    % amount of trials per limit per channel
    fprintf('\t \t creating barplot with counts of bad trials ... ')
    countsBar = figure('Visible', showFigures);
    bar(artefactdef.allCounts,'stacked');
    legend({'Kurtosis', 'Variance', '1/Variance', 'BetaPower', 'GammaPower'})
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
    title(['Percentage bad trials per channel for subject ' subjectNameSession])
    set(gcf, 'Position', get(0,'Screensize'))
    fprintf('done \n')
    
    
    if strcmpi(saveFigures, 'on')
        fprintf('\t \t saving figures ... ')
        
        print(scrollPlot, [summaryFigureFolder filesep subjectNameSession '_scrollPlot' cleanedString '.png'] , '-dpng')
        fprintf('1, ')
        print(freqSpectrum, [summaryFigureFolder filesep subjectNameSession '_freqPlot' cleanedString '.png'] , '-dpng')
        fprintf('2, ')
        print(countsBar, [summaryFigureFolder filesep subjectNameSession '_countsBar' cleanedString '.png'] , '-dpng')
        fprintf('3, ')
        print(pBadBar, [summaryFigureFolder filesep subjectNameSession '_pBadBar' cleanedString '.png'] , '-dpng')
        fprintf('4! ')
        
        fprintf('done \n ')
    end
    close all
end