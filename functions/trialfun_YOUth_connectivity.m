function [trl, event] = trialfun_YOUth_connectivity(cfg)
% Trial function that cuts YOUth connectivity recordings into trials.
%
% A FieldTrip trialfun (see FT_DEFINETRIAL) for the BioSemi recordings of
% the YOUth connectivity task. The triggers are read from the STATUS channel
% of the raw file (with our working copy of FT_READ_EVENT) and converted
% from the sampling rate of the raw file to ``cfg.Fs``, so the trl can be
% used on resampled data. Only the triggers 129 and 139 are used; each one
% starts a trial of ``cfg.trialdef.posttrig`` seconds, and the trigger value
% becomes the condition code in the fourth column of ``trl``.
%
% Trials are made consistent as follows: a trial that would end after the
% end of the recording is cut off at the last sample, a trial that starts
% before the first sample is dropped, and a trial that overlaps the next one
% is ended one sample before the next trial starts. The trials are returned
% sorted by start sample.
%
% An empty ``trl`` (``[]``) is returned when the recording has no STATUS
% triggers, is shorter than ``cfg.trialdef.posttrig`` seconds, or has none
% of the triggers 129/139. The caller has to handle this, since
% FT_DEFINETRIAL errors on an empty trl.
%
% Args:
%     cfg.dataset (str): Raw data file to read the events from.
%     cfg.headerfile (str, optional): File to read the header from. Defaults
%         to ``cfg.dataset``.
%     cfg.Fs (numeric, optional): Sampling rate (Hz) the trl samples are
%         expressed in, i.e. the rate of the data the trl will be applied
%         to. Defaults to the sampling rate of the raw file.
%     cfg.trialdef.pretrig (numeric, optional): Seconds before the trigger
%         at which a trial starts. Defaults to ``0``.
%     cfg.trialdef.posttrig (numeric, optional): Seconds after the trigger
%         at which a trial ends. Defaults to ``60``.
%
% Returns:
%     trl (numeric): N x 4 matrix with begin sample, end sample, offset (in
%         samples, ``-pretrig * cfg.Fs``) and condition code (129 or 139)
%         per trial; ``[]`` if no trials were found.
%     event (struct): The STATUS events of the recording (all values, not
%         only 129/139).
%
% Example:
%     ```matlab
%     cfg = [];
%     cfg.dataset           = 'sub-01.bdf';
%     cfg.trialfun          = 'trialfun_YOUth_connectivity';
%     cfg.trialdef.pretrig  = 0;
%     cfg.trialdef.posttrig = 60;
%     cfg.Fs                = 256;
%     cfg = ft_definetrial(cfg);
%     ```

if ~isfield(cfg, 'dataset')
    error('trialfun_YOUth_connectivity: cfg.dataset is required')
end
if ~isfield(cfg, 'trialdef')
    cfg.trialdef = [];
end
cfg.trialdef.pretrig            = ft_getopt(cfg.trialdef, 'pretrig', 0);
cfg.trialdef.posttrig           = ft_getopt(cfg.trialdef, 'posttrig', 60);
cfg.headerfile                  = ft_getopt(cfg, 'headerfile', cfg.dataset);

% load event and hdr
event = ft_read_event(cfg.dataset);
hdr = ft_read_header(cfg.headerfile);
cfg.Fs = ft_getopt(cfg, 'Fs', hdr.Fs);

% remove all non-status triggers (and events without a value, which would
% make the value and sample vectors below differ in length)
EVtype = {event.type}';
statusIndx = strcmp(EVtype, 'STATUS');
event(~statusIndx) = [];
event(cellfun(@isempty, {event.value})) = [];

EVvalue = [event.value]';
if isempty(EVvalue)
    trl = [];
    return
elseif hdr.nSamples/hdr.Fs<cfg.trialdef.posttrig
    trl = [];
    return
end

% convert the trigger samples to the sampling rate of the data file
EVsample = [event.sample]';
EVsample = ceil((cfg.Fs * EVsample) ./ hdr.Fs);

% length of the recording at that sampling rate (rounded down, so a trial
% never ends beyond the resampled data)
nSamples = floor(hdr.nSamples * cfg.Fs / hdr.Fs);

% only select the trigger values of interest
triggerValues = [129 139];
[triggerIndx, i] = find(EVvalue == triggerValues);
condition = triggerValues(i);

% create trl
preTrig = cfg.trialdef.pretrig * cfg.Fs;
postTrig = cfg.trialdef.posttrig * cfg.Fs;
begsample = EVsample(triggerIndx) - preTrig;
endsample = EVsample(triggerIndx) + postTrig;

% drop trials that would start before the first sample
valid = begsample >= 1;
begsample = begsample(valid);
endsample = endsample(valid);
condition = condition(valid);

if ~isempty(begsample) && ~isempty(endsample)
    endsample(endsample > nSamples) = nSamples;
else
    trl = [];
    return
end

offset = (ones(length(begsample), 1 )*preTrig) .* -1;

%% the last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset condition'];
[~, sortIndx] = sort(trl(:,1));
trl = trl(sortIndx,:);

% end a trial one sample before the next one starts if they overlap
for i = 1:size(trl,1)-1
    if trl(i,2) > trl(i+1,1)
        trl(i,2) = trl(i+1,1)-1;
    end
end

end
