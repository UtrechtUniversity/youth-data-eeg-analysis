function [trl, event]=EEG_Utrecht_Infant_ERP_trialfun_nov2016(cfg);
%Version: 02-Sep-2015b

%% Read in the data and select the parts with the markers
% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
%Determine the number of segments (not necessarily one second)
Srate = hdr.Fs; % sampling rate
Sec = cfg.trialdef.prestim + cfg.trialdef.poststim; % duration trial in seconds
Sseg = round(Srate * Sec); % duration trial in samples
nseg = floor(hdr.nSamples/Sseg); % nr of segments
%nseg=floor(hdr.nSamples/hdr.Fs));

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.prestim  * hdr.Fs);
posttrig =  round(cfg.trialdef.poststim * hdr.Fs);

%Create the segments
trl = [];
sampleinfo = [];
trlbegin = 1 + pretrig;
trlend   = posttrig;
offset   = pretrig;
marker   = cfg.condition;
time = 1;
newtrl   = [trlbegin trlend offset marker time];
%newtrl   = [trlbegin trlend offset marker];
trl   = [trl; newtrl];
%sampleinfo = [sampleinfo; newtrl];

for j=2:nseg %Add the next 50 seconds
    trlbegin = trlend+1;
    trlend   = trlbegin + posttrig-1;
    offset   = pretrig;
    marker   = cfg.condition;
    time = 1;
    newtrl   = [trlbegin trlend offset marker time];
    %%newtrl   = [trlbegin trlend offset marker];
    trl   = [trl; newtrl];
    %sampleinfo = [sampleinfo; newtrl];
end

%data.sampleinfo = sampleinfo;

event=[];
