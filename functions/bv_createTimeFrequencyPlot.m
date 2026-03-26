function tfr = bv_createTimeFrequencyPlot(bdf, trigger)

cfg = [];
cfg.headerfile = bdf;
cfg.dataset = bdf;
cfg.hpfilter = 'yes';
cfg.hpfreq = 1;
cfg.hpinstabilityfix = 'reduce';
cfg.reref = 'yes';
cfg.refchannel = 'all';
cfg.channel = 'EEG';
data = ft_preprocessing(cfg);

cfg.trialdef.pretrig = 0;
cfg.trialdef.posttrig = 60;
cfg.trialdef.triggers = trigger;
cfg.trialfun = 'trialfun_qualitycontrolStep'

try
    cfg = ft_definetrial(cfg)
catch
    warning(lasterr)
    tfr = NaN;
    return
end

dataSocial= ft_redefinetrial(cfg, data);

if size(dataSocial.sampleinfo,1) < 2
    warning('too little trials found')
    tfr = NaN;
    return
end

cfg = [];
cfg.method = 'mtmconvol';
cfg.foi = 1:0.05:9;
cfg.taper = 'hanning';
cfg.t_ftimwin = 2.*ones(1,length(cfg.foi));
cfg.toi = '50%';
cfg.output = 'fourier';
cfg.keeptrials = 'yes';
freq = ft_freqanalysis(cfg, dataSocial);

cfg = [];
cfg.method = 'wpli_debiased';
cfg.channel = {'Fp1', 'Fp2', 'P7', 'P8'};
connectivity = ft_connectivityanalysis(cfg, freq);

tfr = squeeze(nanmean(nanmean(connectivity.wpli_debiasedspctrm,1),2));

