function pxx = magnitudeResponse(cfg, data)
% Plot pwelch frequency spectrum of data file with config file
%
% Possible cfg inputfields:
%   cfg.channel:        add channels for which the magnitude response is 
%                       calculated (default = 'all')
%   cfg.windowLength:   length of window, specified as integer (default =
%                       1000)
%   cfg.noverlap:       Number of overlapped samples, specified as integer. 
%                       Must be smaller than windowLength (default = 50)
%   cfg.freqrange:      frequency range
%
% Copyright (C) 2015-2016, Bauke van der Velde
%
% magnitudeResponse(cfg, data)


% set defaults and error messages
if ~isfield(cfg, 'channel'); cfg.channel = 'all'; end
if ~isfield(cfg, 'noverlap'); cfg.noverlap = 50; end
if ~isfield(cfg, 'windowLength'); cfg.windowLength = 1000; end
if ~isfield(cfg, 'freqrange')
    error('Please add frequency range (cfg.freqrange)')
end

% set variables & data
cfg.channel = ft_channelselection(cfg.channel, data.label);
[~, rawindx] = match_str(cfg.channel, data.label);
Fs = data.fsample;

% if length(data.trial) > 1 % concatenate all trials and add up time 
%     allTrials = [data.trial{:}];
%     trialData = (allTrials(rawindx,:))';
%     totalTime = length(data.time{1})*length(data.time);
%     t = 0:1/Fs:totalTime;
% else % Easy, only one trial
%     trialData = (data.trial{:}(rawindx,:))';
%     t = data.time{:}';
% end

trialData = cellfun(@(a) a(rawindx,:), data.trial, 'Un', 0);
trialData = [trialData{:}]';

% N = size(t,1);
% dF = Fs/N;
% f = -Fs/2:dF:Fs/2-dF;

% Draw figure
[pxx, f]= pwelch(trialData,32*data.fsample,2*data.fsample, data.fsample,'power');
figure; plot(pxx,'LineWidth',3);
set(gca, 'XLim', [cfg.freqrange])
legend(cfg.channel);
