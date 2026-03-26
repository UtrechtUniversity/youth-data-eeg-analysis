function [trl, event] = trialfun_YOUth_QC_resampled(cfg)
% needs:
%   cfg.
if ~isfield(cfg, 'trialdef')
    cfg.trialdef = [];
end

cfg.trialdef.attentiongrabber   = ft_getopt(cfg.trialdef, 'attentiongrabber');
cfg.trialdef.pretrig            = ft_getopt(cfg.trialdef, 'pretrig', 0);
cfg.trialdef.posttrig           = ft_getopt(cfg.trialdef, 'posttrig', 60);

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
EVsample = ceil((cfg.Fs * EVsample) ./ hdr.Fs);

% only select correct triggers based on cfg.triger
[triggerIndx, i] = find(EVvalue==cfg.trialdef.eventvalue);
condition = cfg.trialdef.eventvalue(i);

% create trl
preTrig = cfg.trialdef.pretrig * cfg.Fs;
postTrig = cfg.trialdef.posttrig * cfg.Fs;
begsample = EVsample(triggerIndx) - preTrig;
endsample = EVsample(triggerIndx) + postTrig;

if ~isempty(begsample) && ~isempty(endsample)
    if endsample(end) > hdr.nSamples
        endsample(end) = hdr.nSamples;
    end
else
    trl = [];
    return
end

offset = zeros(length(begsample), 1 );

%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset condition'];
[~, sortIndx] = sort(trl(:,1));
trl = trl(sortIndx,:);

end % function
