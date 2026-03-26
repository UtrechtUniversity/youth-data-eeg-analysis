function data = bv_removeTrials(cfg, data)

optionsFcn = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject = ft_getopt(cfg, 'currSubject');
inputStr = ft_getopt(cfg, 'inputStr');
saveData = ft_getopt(cfg, 'saveData', 'yes');
outputStr = ft_getopt(cfg, 'outputStr', 'cleaned');
triallength = ft_getopt(cfg, 'triallength');

if nargin < 2
    hasdata = false;
else
    hasdata = true;
    saveData = 'no';
end

if ~hasdata % check whether data needs to be loaded from subject.mat file
    
    if isempty(currSubject)
        error('no input data and no cfg.currSubject')
    end
    disp(currSubject)
    
    eval(pathsFcn)
    eval(optionsFcn)
    % Try to load in individuals Subject.mat. If unknown --> throw error.
    [subjectdata, data] = ...
        bv_check4data([PATHS.SUBJECTS filesep currSubject], inputStr);
    
end


if ~isempty(triallength)
    cfg= [];
    cfg.length = triallength;
    cfg.overlap = 0;
    evalc('data = ft_redefinetrial(cfg, data);');
end

mp = get(0, 'MonitorPositions');
[~, fd] = bvLL_frequencyanalysis(data, [0 50], 'fourier');
fig1 = figure;
set(gcf, 'Position', mp(size(mp,1),:))
semilogy(fd.freq, squeeze(mean(fd.powspctrm)), 'LineWidth',2)
drawnow
pause(1)
close(fig1)


fprintf('\t starting up visual artifact rejection ...')
cfg = [];
cfg.method = 'summary';
cfg.layout = 'biosemi32.lay';
cfg.keeptrial = 'no';
cfg.keepchannel = 'nan';
evalc('dataClean = ft_rejectvisual(cfg, data);');
fprintf('done! \n')

rmchans = data.label(sum(isnan([dataClean.trial{:}]),2) == size([dataClean.trial{:}],2));

if ~isempty(rmchans)
    subjectdata.channels2remove = cat(1, subjectdata.channels2remove, rmchans);

    cfg = [];
    cfg.layout = 'biosemi32.lay';
    cfg.method = 'triangulation';
    evalc('neighbours = ft_prepare_neighbours(cfg);');
    
    cfg = [];
    cfg.badchannel = rmchans;
    cfg.method = 'weighted';
    cfg.neighbours = neighbours;
    cfg.layout = 'biosemi32.lay';
    evalc('dataClean = ft_channelrepair(cfg, dataClean);');
end

[~, fdClean] = bvLL_frequencyanalysis(dataClean, [0 50], 'fourier');
fig2 = figure;
set(gcf, 'Position', mp(size(mp,1),:))
semilogy(fd.freq, squeeze(mean(fd.powspctrm)), 'LineWidth',2)
drawnow
pause(1)
close(fig2)
fig3 = figure;
set(gcf, 'Position', mp(size(mp,1),:))
semilogy(fdClean.freq, squeeze(mean(fdClean.powspctrm)), 'LineWidth',2)
drawnow
pause(1)
close(fig3)

data = dataClean;

if strcmpi(saveData, 'yes')
    bv_saveData(subjectdata, data, outputStr)
end