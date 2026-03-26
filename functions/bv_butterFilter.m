function [filt] = bv_butterFilter(dat, freqrange, Fs)

if nargin < 3
    error('No sampling frequency given')
end
if nargin < 2
    error('No frequency range given')
end
if nargin < 1
    error('No data given')
end
    
if ~iscell(dat)
    dat = {dat};
end

N = [];
type = 'but';

if length(freqrange) > 2
    error('unknown freqrange')
end

filt = cell(1, length(dat));
if freqrange(1) ~= Inf
    for iTrl = 1:length(dat)
        currData = dat{iTrl};
        filt{iTrl} = ft_preproc_highpassfilter(currData,Fs,freqrange(1),N,type);
    end
end

if freqrange(2) ~= Inf
    for iTrl = 1:length(filt)
        currData = filt{iTrl};
        filt{iTrl} = ft_preproc_lowpassfilter(currData,Fs,freqrange(2),N,type);
    end
end

