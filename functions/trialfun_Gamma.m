function [trl, event] = trialfun_Gamma(cfg)
%% the first part is common to all trial functions
% read the header (needed for the samping rate) and the events

%% from here on it becomes specific to the experiment and the data format
% for the events of interest, find the sample numbers (these are integers)
% for the events of interest, find the trigger values (these are strings in the case of BrainVision)

% load event and hdr
event = ft_read_event(cfg.dataset);
hdr = ft_read_header(cfg.headerfile);

% remove all non-status triggers
EVtype = {event.type}';
statusIndx = strcmp(EVtype, 'STATUS');
event(~statusIndx) = [];

toi = [1, 2, 4, 8, 16, 48, 80, 112];

% resample sampling rate, to rate used with data file
EVvalue = [event.value]';
EVsample = [event.sample]';
EVsample = round((cfg.Fs* EVsample) ./ hdr.Fs);

toi = [1, 2, 4, 8, 16, 48, 80, 112];
tIndex = find(ismember(EVvalue, toi));

begsample = EVsample(tIndex(1));
endsample = EVsample(tIndex(end));

offset = 0;


%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset];

end % function
