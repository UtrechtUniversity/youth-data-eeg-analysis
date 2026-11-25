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
% sorted by start sample. Events on the first sample of a part after the
% first are ignored (the status channel can still hold the trigger of the
% previous part there). A trial is never cut off where two parts of a
% stitched recording meet: it simply continues into the next part (see
% ``cfg.partOffsets``).
%
% An empty ``trl`` (``[]``) is returned when the recording has no STATUS
% triggers, is shorter than ``cfg.trialdef.posttrig`` seconds, or has none
% of the triggers 129/139. The caller has to handle this, since
% FT_DEFINETRIAL errors on an empty trl.
%
% Args:
%     cfg.dataset (str or cell array of str): Raw data file(s) to read the
%         events from. Several files are the parts of one stitched
%         recording, in the order they are stitched in.
%     cfg.headerfile (str or cell array of str, optional): File(s) to read
%         the header from, one per entry of ``cfg.dataset``. Defaults to
%         ``cfg.dataset``.
%     cfg.partOffsets (numeric, optional): For every part, the number of
%         samples (at ``cfg.Fs``) in the stitched data before that part
%         starts, including the padding of the gaps between the parts.
%         Defaults to ``0`` for every part, which is right for a single
%         file.
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
%         only 129/139). For stitched recordings, the events of all parts
%         one after the other, with the samples of their own file.
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

datasets  = cellstr(cfg.dataset);
hdrfiles  = cellstr(cfg.headerfile);
nParts    = numel(datasets);
offsets   = ft_getopt(cfg, 'partOffsets', zeros(1, nParts));
if numel(hdrfiles) ~= nParts || numel(offsets) ~= nParts
    error('trialfun_YOUth_connectivity: cfg.dataset, cfg.headerfile and cfg.partOffsets must have one entry per part')
end

% load the events and the header of every part; the trigger samples are
% converted to the sampling rate of the data file and moved to the position
% of their part in the stitched recording
event      = [];
EVvalue    = [];
EVsample   = [];
nSamples   = 0;       % end of the (stitched) recording at cfg.Fs
duration   = 0;       % amount of recorded data (s)
for p = 1:nParts
    partEvent = ft_read_event(datasets{p});
    hdr = ft_read_header(hdrfiles{p});
    if p == 1
        cfg.Fs = ft_getopt(cfg, 'Fs', hdr.Fs);
    end

    % remove all non-status triggers (and events without a value, which
    % would make the value and sample vectors below differ in length)
    partEvent(~strcmp({partEvent.type}, 'STATUS')) = [];
    partEvent(cellfun(@isempty, {partEvent.value})) = [];

    % a part can start while the status channel still holds the trigger
    % value of the previous part, which reads as a trigger on the first
    % sample; that is the continuation of a trigger, not a new one
    if p > 1
        partEvent([partEvent.sample] == 1) = [];
    end

    if isempty(event)
        event = partEvent(:);
    else
        event = [event; partEvent(:)]; %#ok<AGROW>
    end
    EVvalue  = [EVvalue; [partEvent.value]']; %#ok<AGROW>
    EVsample = [EVsample; ceil((cfg.Fs * [partEvent.sample]') ./ hdr.Fs) + offsets(p)]; %#ok<AGROW>

    % length of the recording at the sampling rate of the data (rounded
    % down, so a trial never ends beyond the resampled data)
    nSamples = offsets(p) + floor(hdr.nSamples * cfg.Fs / hdr.Fs);
    duration = duration + hdr.nSamples / hdr.Fs;
end

if isempty(EVvalue)
    trl = [];
    return
elseif duration < cfg.trialdef.posttrig
    trl = [];
    return
end

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
