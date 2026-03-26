function W = bv_showConnectivityMatrices(cfg, connectivity)

inputStr 	= ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr');
currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');
saveFigures = ft_getopt(cfg, 'saveFigures');
freqLabel   = ft_getopt(cfg, 'freqLabel', {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'});
freqRange   = ft_getopt(cfg, 'freqRange',  {[1 3], [3 6], [6 9], [9 12], [12 25], [25 48]});

if ~iscell(freqLabel)
    freqLabel = {freqLabel};
end
if ~iscell(freqRange)
    freqRange = {freqRange};
end

if nargin < 2
    disp(currSubject)
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    try
        [subjectdata, connectivity] = bv_check4data(subjectFolderPath, inputStr);
    catch
        fprintf('\t data file not found, skipping ... ')
        return
    end
    
    subjectdata.cfgs.(outputStr) = cfg;
end

if not(length(freqLabel) == length(freqRange))
    disp('')
    errorStr = sprintf('cfg.freqLabel (%1.0f) and cfg.freqRange (%1.0f) differ in length', ...
        length(freqLabel), length(freqRange));
    error(errorStr)
end

fnames = fieldnames(connectivity);
fname2use = fnames(not(cellfun(@isempty, strfind(fnames, 'spctrm')))); 
method = regexprep(fname2use{:},'spctrm','');


for iFreq = 1:length(freqLabel)
    cFreqLabel = freqLabel{iFreq};
    cFreqRange = freqRange{iFreq};
    
    fprintf('\t %s \n', cFreqLabel)
    
    
    
    
    switch method
        case 'wpli_debiased'
            fprintf('\t\t selecting data ... ')
            cfg = [];
            cfg.frequency = cFreqRange;
            evalc('currConnectivity = ft_selectdata(cfg, connectivity);');
            fprintf('done! \n')
            
            fprintf('\t\t creating connectivity matrix ... ')
            W = mean(currConnectivity.wpli_debiasedspctrm,3);
        case 'pli'
            fprintf('\t\t creating connectivity matrix ... ')
            freqIndx = find(not(cellfun(@isempty, strfind(connectivity.freq, cFreqLabel))));
            if ~isempty(freqIndx)
                W = connectivity.plispctrm(:,:,freqIndx);
            else
                error('freqLabel %s not found', cFreqLabel)
            end
    end
    
    
    h = figure;
    imagesc(W)
    title([currSubject ': Connectivity matrix ' cFreqLabel], 'FontSize', 20)
    set(gca, 'XTick', 1:length(connectivity.label), 'XTickLabel', connectivity.label, 'XTickLabelRotation', 90)
    set(gca, 'YTick', 1:length(connectivity.label), 'YTickLabel', connectivity.label)
    setAutoLimits(gca)
    ylabel('Channels', 'FontSize', 14)
    xlabel('Channels', 'FontSize', 14)
    axis('square')
    fprintf('done! \n')
    colorbar
    
    xScreenLength = 1;
    yScreenLength = 1;
    
    if exist('WindowSize', 'file')
        [xScreenSize, yScreenSize] = WindowSize(0);
        set(0, 'units', 'pixels')
        realScreenSize = get(0, 'ScreenSize');
        xDiff = xScreenSize / realScreenSize(3);
        xScreenLength = xScreenLength * xDiff;
        yDiff = yScreenSize / realScreenSize(4);
        yScreenLength = yScreenLength * yDiff;
    end
    
    set(gcf, 'units', 'normalized', 'Position', [0 0 xScreenLength/2 yScreenLength])
    drawnow;
    
    
    if strcmpi(saveFigures, 'yes')
        if ~isfield(subjectdata.PATHS, 'FIGURES')
            subjectdata.PATHS.FIGURES = [subjectdata.PATHS.SUBJECTDIR filesep 'figures'];
        end
        if ~exist(subjectdata.PATHS.FIGURES, 'dir')
            mkdir(subjectdata.PATHS.FIGURES)
        end
        
        picFilename = [subjectdata.subjectName '_' cFreqLabel '_' outputStr '.png'];
        fprintf('\t\t saving %s ... ', picFilename)
        saveas(gcf, [subjectdata.PATHS.FIGURES filesep picFilename])
        fprintf('done! \n')
        
        close(h)
    end
%    close(h) 
end





