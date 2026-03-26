function [trl, event] = trialfun_YOUth_presentation_resampled(cfg)
%% the first part is common to all trial functions
% read the header (needed for the samping rate) and the events

%% from here on it becomes specific to the experiment and the data format
% for the events of interest, find the sample numbers (these are integers)
% for the events of interest, find the trigger values (these are strings in the case of BrainVision)

% load event and hdr
event = ft_read_event(cfg.dataset);
event(1) = [];
hdr = ft_read_header(cfg.headerfile);

% remove all non-status triggers
EVtype = {event.type}';
statusIndx = strcmp(EVtype, 'STATUS');
event(~statusIndx) = [];

% resample sampling rate, to rate used with data file
EVvalue = [event.value]';
EVsample = [event.sample]';
EVsample = ceil((cfg.Fs * EVsample) ./ hdr.Fs);

% remove attentiongrabber triggers
attentionGrabber = EVvalue == 126 | EVvalue == 114 | EVvalue == 115;
EVvalue(attentionGrabber)   = [];
EVsample(attentionGrabber)  = [];

trigIndx = find(EVvalue>200);
preTrig = round(0 * cfg.Fs);
postTrig = round(1 * cfg.Fs);

begsample = EVsample(trigIndx) + preTrig;
endsample = EVsample(trigIndx) + postTrig;
offset = ones(length(begsample),1) .* preTrig;
condition = EVvalue(trigIndx);

%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset condition];

end % function
