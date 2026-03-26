function lay = bv_quickCreateLayout(labels)

cfg = [];
cfg.layout = 'EEG1010';
cfg.channel = labels;
cfg.feedback = 'no';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';

lay = ft_prepare_layout(cfg);