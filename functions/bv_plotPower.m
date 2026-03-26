function [y_toplot, x_toplot] = bv_plotPower(cfg, data)

inputStr 	= ft_getopt(cfg, 'inputStr');
currSubject = ft_getopt(cfg, 'currSubject');
channel     = ft_getopt(cfg, 'channel', 'all');
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');
calcMean    = ft_getopt(cfg, 'calcMean', 'yes');
freqRange   = ft_getopt(cfg, 'freqRange', [0 20]);

if nargin < 2
    disp(currSubject)
    
    eval(pathsFcn)
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    try
        [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    catch
        error('inputStr data not found')
    end
else
    fprintf('Own input \n')
end

cfg = [];
cfg.channel = channel;
evalc('data = ft_selectdata(cfg, data);');

if isempty(data.label)
    fprintf('\t given channel not found for subject, skipping ... \n')
    return
end

output = 'fourier';
fprintf('\t calculating frequency spectrum ...')
evalc('[freq fd] = bvLL_frequencyanalysis(data, freqRange, output);');
fprintf('done! \n')

if strcmpi(calcMean, 'yes')
    y_toplot = log10(squeeze(nanmean(nanmean(fd.powspctrm),2)));
    x_toplot = fd.freq;
    plot(x_toplot, y_toplot, 'LineWidth', 2)
else
    figure;
    plot(freq.freq, log10(squeeze(nanmean(fd.powspctrm,1))))
    legend(freq.label)
    set(gca, 'FontSize', 20)
    drawnow
end
% set(gca, 'YLim', [-1 2])
set(gca, 'XLim', [0 20])


