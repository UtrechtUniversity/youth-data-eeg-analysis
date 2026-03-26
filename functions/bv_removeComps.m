function data = bv_removeComps(cfg, data, comp)

currSubject         = ft_getopt(cfg, 'currSubject');
optionsFcn          = ft_getopt(cfg, 'optionsFcn');
saveData            = ft_getopt(cfg, 'saveData');
outputStr           = ft_getopt(cfg, 'outputStr');
dataStr             = ft_getopt(cfg, 'dataStr');
compStr             = ft_getopt(cfg, 'compStr');
automaticRemoval    = ft_getopt(cfg, 'automaticRemoval');
saveFigures         = ft_getopt(cfg, 'saveFigures');
showFigures         = ft_getopt(cfg, 'saveFigures');
blinkremoval        = ft_getopt(cfg, 'blinkremoval', 'no');
gammaremoval        = ft_getopt(cfg, 'gammaremoval', 'no');
deltaremoval        = ft_getopt(cfg, 'deltaremoval', 'no');

if strcmpi(automaticRemoval, 'yes')
    automaticFlag = 1;
else
    automaticFlag = 0;
end

if nargin < 3
    
    disp(currSubject)
    eval(optionsFcn)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    if isempty(dataStr)
        error('cfg.dataStr not given while also no data input variable given')
    end
    if isempty(compStr)
        error('cfg.compStr not given while also no data input variable given')
    end
    if isempty(currSubject)
        error('no cfg.currSubject while also no data/comp input variable given')
    end
    
    [subjectdata, data, comp] = bv_check4data(subjectFolderPath, dataStr, compStr);
end

oldcfg = cfg;
subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, oldcfg);

if strcmpi(showFigures, 'yes')
    fprintf('\t creating frequency plot ... ')
    
    output = 'fourier';
    freqrange = [0 50];
    evalc('[freq, fd] = bvLL_frequencyanalysis(data, freqrange, output, 1);');
    freqFields  = fieldnames(freq);
    field2use   = freqFields{not(cellfun(@isempty, strfind(freqFields, 'spctrm')))};
    
    mp = get(0, 'MonitorPositions');
    figure;
    set(gcf, 'Position', mp(1,:));
    semilogy(freq.freq, squeeze(mean(fd.powspctrm)), 'LineWidth', 2)
    legend(data.label)
    set(gca, 'YLim', [0 Inf])
    % set(gcf, 'units', 'normalized', 'Position', [0 0 xScreenLength yScreenLength])
    
    if strcmpi(saveFigures, 'yes')
        cfg = [];
        cfg.fighandle   = gcf;
        cfg.outputStr   = outputStr;
        cfg.filename    = [currSubject '_freq_before'];
        cfg.figtitle    = strrep(cfg.filename, '_','-');
        
        bv_saveFigures(cfg)
    end
    fprintf('done! \n')
end


if automaticFlag
    fprintf('\t automatic component removal started ... \n')
    
    cfg = [];
    cfg.blinkremoval = blinkremoval;
    cfg.gammaremoval = gammaremoval;
    cfg.deltaremoval = deltaremoval;
    
    rmComps = automaticCompRemoval(cfg, data, comp);
    
else
    
    fprintf('\t preparing layout...')
    cfg = [];
    cfg.channel  = data.label;
    cfg.layout   = 'EEG1010';
    cfg.feedback = 'no';
    cfg.skipcomnt  = 'yes';
    cfg.skipscale  = 'yes';
    evalc('lay = ft_prepare_layout(cfg);');
    fprintf('done! \n')
    
    fprintf('\t showing components ... \n')
    
    %     cfg = [];
    %     cfg.component = 1:length(comp.label); % specify the component(s) that should be plotted
    %     cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
    %     cfg.comment   = 'no';
    %     cfg.compscale = 'local';
    %     cfg.interactive = 'no';
    %     figure();
    %     evalc('ft_topoplotIC(cfg, comp);');
    % %     set(gcf, 'units', 'normalized', 'Position', [xScreenLength/2 yScreenLength xScreenLength/2 yScreenLength])
    %
    cfg = [];
    cfg.badPartsMatrix  = [];
    cfg.horzLim         = 60;
    cfg.scroll          = 1;
    cfg.visible         = 'on';
    cfg.channel         = 'all';
    fig2 = scrollPlotData(cfg, comp);
    
    fprintf('\t press SPACE after inspecting components \n')
    pause;
    
    
    inputStr = sprintf('\t Input component numbers to be removed, seperated by a comma. ');
    
    rmComps = input(inputStr', 's');
    rmComps = strrep(rmComps, ' ', '');
    rmComps = strsplit(rmComps, ',');
    rmComps = str2double(rmComps);
    
end


if ~isnan(rmComps)
    rmComps = unique(rmComps);
    
    rmCompIndx = rmComps;
    rmComps = reshape(rmComps, length(rmComps), 1);
    
    if strcmpi(showFigures, 'yes')
        badPartsMatrix = [repmat(1:length(comp.trial),1,length(rmComps))', ...
            sort(repmat(rmComps, length(comp.trial), 1))];
        
        cfg = [];
        cfg.badPartsMatrix  = badPartsMatrix;
        cfg.horzLim         = 60;
        cfg.scroll          = 0;
        cfg.visible         = 'on';
        cfg.channel         = 'all';
        fig1 = scrollPlotData(cfg, comp);
        %     set(gcf, 'units', 'normalized', 'Position', [xScreenLength/2 yScreenLength xScreenLength/2 yScreenLength])
        
        cfg = [];
        cfg.component = rmComps; % specify the component(s) that should be plotted
        cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
        cfg.comment   = 'no';
        cfg.compscale = 'local';
        cfg.interactive = 'no';
        fig2 = figure();
        evalc('ft_topoplotIC(cfg, comp);');
        %     set(gcf, 'units', 'normalized', 'Position', [0 0 xScreenLength/2 yScreenLength])
        
        
        if strcmpi(saveFigures, 'yes')
            
            filename = [currSubject '_badComponentsTrial.png'];
            cfg = [];
            cfg.fighandle   = fig1;
            cfg.outputStr   = outputStr;
            cfg.filename    = filename;
            bv_saveFigures(cfg)
            
            filename = [currSubject '_badComponentsTopo.png'];
            cfg = [];
            cfg.fighandle   = fig2;
            cfg.outputStr   = outputStr;
            cfg.filename    = filename;
            bv_saveFigures(cfg)
            
        end
    end
    badComponents = textscan(num2str(rmComps'),'%s');
    
    fprintf(['\t removing component(s): ' repmat('%s, ',1,length(badComponents{:})), ...
        ' ... '], badComponents{:}{:})
    
    badComponents = cellfun(@str2num, badComponents{:});
    oldcfg.removedComps = badComponents;
    
    cfg             = [];
    cfg.component   = badComponents;
    evalc('data = ft_rejectcomponent(cfg,comp,data);');
    
    fprintf('done! \n')
    
    if strcmpi(showFigures, 'yes')
        output = 'fourier';
        freqrange = [0 50];
        evalc('[freq, fd] = bvLL_frequencyanalysis(data, freqrange, output, 1);');
        
        freqFields  = fieldnames(freq);
        field2use   = freqFields{not(cellfun(@isempty, strfind(freqFields, 'spctrm')))};
        
        fig3 = figure;
        set(gcf, 'Position', mp(1,:));
        semilogy(fd.freq, squeeze(mean(fd.powspctrm)), 'LineWidth', 2)
        legend(data.label)
        set(gca, 'YLim', [-4 Inf])
        %     set(fig3, 'units', 'normalized', 'Position', [0 0 xScreenLength yScreenLength])
        
        drawnow;
        
        if strcmpi(saveFigures, 'yes')
            cfg = [];
            cfg.fighandle   = fig3;
            cfg.outputStr   = outputStr;
            cfg.filename    = [currSubject '_freq_after'];
            cfg.figtitle    = strrep(cfg.filename, '_','-');
            bv_saveFigures(cfg)
            
            close all
        end
    end
    if strcmpi(saveData, 'yes')
        
        subjectdata.rmComps = badComponents;
        
        cRemFilename = [currSubject '_' outputStr '.mat'];
        subjectdata.PATHS.COMPREMOVED = [subjectdata.PATHS.SUBJECTDIR filesep cRemFilename];
        
        fprintf('\t Saving %s ... ', cRemFilename)
        save(subjectdata.PATHS.COMPREMOVED, 'data')
        fprintf('done! \n')
        
        subjectdata.cfgs.(outputStr) = oldcfg;
        fprintf('\t Saving Subject.mat ... ')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
        fprintf('done! \n')
    end
else
    if strcmpi(saveData, 'yes')
        
        subjectdata.rmComps = [];
        
        cRemFilename = [currSubject '_' outputStr '.mat'];
        subjectdata.PATHS.COMPREMOVED = [subjectdata.PATHS.SUBJECTDIR filesep cRemFilename];
        
        fprintf('\t Saving %s ... ', cRemFilename)
        save(subjectdata.PATHS.COMPREMOVED, 'data')
        fprintf('done! \n')
        
        subjectdata.cfgs.(outputStr) = oldcfg;
        fprintf('\t Saving Subject.mat ... ')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
        fprintf('done! \n')
    end
end
