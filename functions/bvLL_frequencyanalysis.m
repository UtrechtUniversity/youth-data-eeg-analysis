function [freq, fd] = bvLL_frequencyanalysis(data, freqrange, output, redefinetrial)

if nargin < 4
    redefinetrial = 1;
end
if nargin < 3
    output = 'fourier';
end
if nargin < 2
    error('Please input data')
end
if nargin < 1
    error('Please input config file')
end

strial = size(data.trial{1},2) / data.fsample;

if redefinetrial && strial>5
    cfg =[];
    cfg.length = 5;
    cfg.overlap = 0;
    data = ft_redefinetrial(cfg, data);
end

cfg = [];
cfg.method      = 'mtmfft';
cfg.taper       = 'hanning';
cfg.tapsmofrq   = 2;
cfg.output      = output;
cfg.foilim     = freqrange;
cfg.pad         ='nextpow2';
cfg.keeptrials  = 'yes';
cfg.keeptapers  = 'yes';
freq = ft_freqanalysis(cfg, data);
fd = ft_freqdescriptives(cfg, freq);

