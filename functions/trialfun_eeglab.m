function [trl, event] = trialfun_eeglab(cfg)
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
statusIndx = strcmp(EVtype, 'trigger');
event(~statusIndx) = [];

% resample sampling rate, to rate used with data file
EVvalue = [event.value]';
EVsample = [event.sample]';
EVsample = round((cfg.Fs* EVsample) ./ hdr.Fs);

% only select correct triggers based on cfg.triger
triggerSocialIndx = find(EVvalue==64651);
triggerNonsocialIndx = find(EVvalue==64641);
triggerIndx = find(EVvalue==64651 | EVvalue==64641);

% finding conditions
condition = zeros(1, length(triggerIndx));
condition(ismember(triggerIndx, triggerSocialIndx)) = 129;
condition(ismember(triggerIndx, triggerNonsocialIndx)) = 139;

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
