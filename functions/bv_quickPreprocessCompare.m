function data = quickPreprocessCompare(dataset)

cfg = [];
cfg.dataset = dataset;
cfg.headerfile = dataset;
cfg.channel = 'eeg';
% cfg.trialdef.eventtype = 'STATUS';
% cfg.trialdef.eventvalue = 12;
% cfg.trialdef.prestim = 0;
% cfg.trialdef.poststim = 60;
% cfg = ft_definetrial(cfg);
cfg.padding = 10;
cfg.lpfilter = 'yes';
cfg.lpfreq = 100;
cfg.lpfilttype = 'firws';
cfg.hpfilter = 'yes';
cfg.hpfreq = 1;
cfg.hpfilttype = 'firws';
cfg.bsfilter = 'yes';
cfg.bsfreq = [48 52];
cfg.hpfilttype = 'firws';
data = ft_preprocessing(cfg);


