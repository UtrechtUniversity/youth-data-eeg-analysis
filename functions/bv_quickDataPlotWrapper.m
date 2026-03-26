function bv_quickDataPlotWrapper(data)

trialdata = [data.trial{:}];
mLimit = median(mean(abs(trialdata)));

cfg = [];
cfg.viewmode    = 'vertical';
cfg.blocksize   = 10;
cfg.ylim        = [-mLimit mLimit];
ft_databrowser(cfg, data);
