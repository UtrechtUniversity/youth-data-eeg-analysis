function [trl, event] = trialfun_YOUth_QC(cfg)
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

% resample sampling rate, to rate used with data file
EVvalue = [event.value]';
EVsample = [event.sample]';
EVsample = round((cfg.Fs* EVsample) ./ hdr.Fs);

% remove attentiongrabber triggers
attentionGrabber = EVvalue == 126 | EVvalue == 114 | EVvalue == 115;
EVvalue(attentionGrabber)   = [];
EVsample(attentionGrabber)  = [];

% only select triggers with correct length
triggerLength = diff([EVsample; hdr.nSamples]) / cfg.Fs;
corrTriggerLength = triggerLength > 20;
EVvalue(~corrTriggerLength) = [];
EVsample(~corrTriggerLength) = [];

% only select correct triggers based on cfg.triger
triggerSocialIndx = find(EVvalue==cfg.trigger(1));
triggerNonsocialIndx = find(EVvalue==cfg.trigger(2));
triggerIndx = find(EVvalue==cfg.trigger(1) | EVvalue==cfg.trigger(2));

% finding conditions
condition = zeros(1, length(triggerIndx));
condition(ismember(triggerIndx, triggerSocialIndx)) = cfg.trigger(1);
condition(ismember(triggerIndx, triggerNonsocialIndx)) = cfg.trigger(2);

% create trl
preTrig = 0 * cfg.Fs;
postTrig = 60 * cfg.Fs;
begsample = EVsample(triggerIndx) - preTrig;
endsample = EVsample(triggerIndx) + postTrig;

if ~isempty(begsample) && ~isempty(endsample)
    if endsample(end) > hdr.nSamples
        endsample(end) = hdr.nSamples;
%         begsample(end) = [];
    end
else
    trl = [];
    return
end

offset = zeros(length(begsample), 1 );

%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset condition'];

end % function
