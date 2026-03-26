function [a, levelLog, levelIndx] = plotBadTrials(data, crit, level)

a = max(crit);

if length(level) == 2
    levelLog = a > level(1) & a < level(2);
elseif length(level) == 1
    levelLog = a < level;
else
    error('no more than 2 values in level variable allowed')
end

levelIndx = find(levelLog == 1);
sum(levelLog)
plot(a, '*')
hold on 
plot(levelIndx, a(levelIndx), 'Color', 'r', 'LineStyle', 'none', 'Marker', '*')

cfg = [];
cfg.trials = levelLog;
badTrials = ft_selectdata(cfg, data);

cfg =[];
cfg.viewmode = 'vertical';
ft_databrowser(cfg, badTrials)