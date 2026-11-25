function [ data, subjectdata ] = preprocResample(cfg)
% Reads in, preprocesses, and (optionally) resamples raw EEG data.
%
% Built on FT_PREPROCESSING of the FieldTrip toolbox. Applies the
% following steps, in this order, each only if configured:
%   1) reading in data (skipping flagged channels, if removing them)
%   2) interpolating flagged channels
%   3) resampling
%   4) filtering
%   5) rereferencing
%   6) wavelet thresholding
%   7) cutting data into trials
%
% A session can consist of several raw files (see
% CREATESUBJECTFOLDERS). Steps 1-6 are done on every file on
% its own, so no filter runs across the place where two files meet. A file
% that can't be read in (incomplete, truncated) is dropped and recorded in
% ``subjectdata.rawFiles``; the subject is only removed when no file can
% be read. The files are then stitched into one recording, with the real
% time between two files (``subjectdata.rawFiles.gapToPrevious``) as NaN
% samples in between (not more than the longest trial of the trial
% function). Step 7 cuts the trials from this stitched recording, so a trial
% that spans the place where two files meet is not cut off there: it holds
% the data of both files, and NaN where there is a gap. Later steps have to
% treat the NaN samples as unusable data.
%
% Can be run in two ways: (1) on a subject created by
% CREATESUBJECTFOLDERS (``cfg.currSubject``), reading subject
% info from - and optionally saving results back to - that subject's
% Subject.mat; or (2) directly on a raw dataset (``cfg.dataset`` and
% ``cfg.hdrfile``), in which case nothing is saved.
%
% Args:
%     cfg.currSubject (str): Subject folder name (found in
%         ``PATHS.SUBJECTS``). Required when ``cfg.dataset``/``cfg.hdrfile``
%         are not given.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Only used with
%         ``cfg.currSubject``. Defaults to ``'setPaths'``.
%     cfg.dataset (str or cell array of str): Raw dataset filename(s).
%         Required, together with ``cfg.hdrfile``, when ``cfg.currSubject``
%         is not used. Several files are stitched in the given order,
%         directly after each other (no gaps).
%     cfg.hdrfile (str or cell array of str): Header filename(s), one per
%         dataset. See ``cfg.dataset``.
%     cfg.saveData (str, optional): Whether to save the preprocessed data
%         and Subject.mat to disk (``'yes'`` or ``'no'``). Forced to
%         ``'no'`` (with a warning) when running on ``cfg.dataset``.
%         Defaults to ``'no'``.
%     cfg.outputName (str, optional): Label for the output file
%         (``<subjectName>_<outputName>.mat``), its ``subjectdata.PATHS``
%         entry (upper-cased), and this run's config in
%         ``subjectdata.cfgs``. Defaults to ``'preproc'``.
%     cfg.overwrite (str, optional): Whether to overwrite an existing
%         output file (``'yes'`` or ``'no'``). When ``'no'`` and
%         ``cfg.saveData`` is ``'yes'``, an existing output makes the
%         function return empty without doing anything. Defaults to
%         ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``; logical ``true`` is also accepted).
%         Defaults to ``'no'``.
%     cfg.channels (cell array of str, optional): Channels (or FieldTrip
%         channel groups, e.g. ``{'EEG'}``) to read in, passed to
%         FT_PREPROCESSING as ``cfg.channel``. With more than one entry,
%         the matching channel indices are looked up with
%         CHECKCHANNELS and only those are read from the header.
%         Defaults to all channels.
%     cfg.chanindx (numeric, optional): Channel indices to read in. Takes
%         precedence over ``cfg.channels`` for choosing which channels
%         are read from the header.
%     cfg.trialfun (str, optional): Filename of the trial function used to
%         cut the data into trials (must be on the MATLAB path, see
%         TRIALFUNYOUTHCONNECTIVITY). Leave empty to skip trial cutting.
%     cfg.pretrig (number, optional): Seconds before each event to include,
%         passed to the trial function as ``cfg.trialdef.pretrig`` (the
%         trial function's own default applies when empty).
%     cfg.posttrig (number, optional): Seconds after each event to include,
%         passed to the trial function as ``cfg.trialdef.posttrig`` (the
%         trial function's own default applies when empty).
%     cfg.resampleFs (number, optional): New sampling rate, in Hz. No
%         resampling when empty.
%     cfg.hpfreq (number, optional): High-pass filter cut-off, in Hz.
%     cfg.lpfreq (number, optional): Low-pass filter cut-off, in Hz.
%     cfg.notchfreq (number, optional): Notch filter frequency, in Hz.
%     cfg.filttype (str, optional): Filter type: ``'but'`` (two-pass
%         Butterworth) or ``'firws'`` (windowed-sinc FIR). Falls back to
%         FieldTrip's default (``'but'``) when empty. See
%         FILTEREEGDATA.
%     cfg.reref (str, optional): Whether to rereference the data (``'yes'``
%         or ``'no'``). Defaults to ``'no'``.
%     cfg.refelec (str or cell array of str, optional): Rereference
%         channel(s); ``'all'`` is a common average reference. Defaults to
%         ``'all'``.
%     cfg.refmethod (str, optional): Rereference method, passed to
%         FT_PREPROCESSING as ``cfg.refmethod``. Defaults to ``'avg'``.
%     cfg.removechans (str, optional): Whether to skip the channels listed
%         in ``subjectdata.flaggedChannels`` (set by REMOVECHANNELS)
%         when reading in data (``'yes'`` or ``'no'``). Defaults to
%         ``'no'``.
%     cfg.channels2remove (str or cell array of str, optional): Channel
%         labels to remove. Overrides ``subjectdata.flaggedChannels`` when
%         given and ``cfg.removechans`` is ``'yes'``; when empty, the
%         existing ``subjectdata.flaggedChannels`` are used.
%     cfg.interpolate (str, optional): Whether to interpolate the removed
%         channels (``'yes'`` or ``'no'``). Requires ``cfg.removechans``
%         to be ``'yes'``. Defaults to ``'no'``.
%     cfg.interpMethod (str, optional): Interpolation method, passed to
%         FT_CHANNELREPAIR. Defaults to ``'average'``.
%     cfg.waveletThresh (str, optional): Whether to apply wavelet
%         thresholding, based on HAPPE v3 (needs the Wavelet Toolbox)
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%
% Returns:
%     data (struct): Preprocessed FieldTrip data. Empty (``[]``) if the
%         output already exists and ``cfg.overwrite`` is ``'no'``, or if
%         the subject was removed (via REMOVINGSUBJECTS) because no file
%         could be read (incomplete/truncated file, read error), or no
%         trials were found.
%     subjectdata (struct): Updated subject info (not assigned when
%         returning early because the output already exists). Besides
%         the trial count ``nTrialsPreproc``, it holds (when cutting
%         trials) ``nEdgeTrials`` (trials that span the place where two
%         files meet), ``nEdgeTrialsGap`` (of those, the ones with NaN
%         samples because the files were not directly after each other),
%         ``nRawFilesWithTrials``, and per file ``rawFiles(k).nTrials``
%         (trials that start in that file). ``PATHS.DATAFILES``,
%         ``PATHS.HDRFILES``, ``rawFiles`` and ``nRawFilesUsed`` are
%         updated for files dropped here.
%
% Example:
%     ```matlab
%     cfg             = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.outputName  = 'PREPROC';
%     cfg.saveData    = 'yes';
%     cfg.channels    = {'EEG'};
%     cfg.resampleFs  = 512;
%     cfg.hpfreq      = 0.16;
%     cfg.lpfreq      = 70;
%     cfg.notchfreq   = 50;
%     cfg.trialfun    = 'trialfunYOUthConnectivity';
%     data = preprocResample(cfg);
%     ```

%% get options
currSubject         = ft_getopt(cfg, 'currSubject');
pathsFcn            = ft_getopt(cfg, 'pathsFcn', 'setPaths');
trialfun            = ft_getopt(cfg, 'trialfun');
pretrig             = ft_getopt(cfg, 'pretrig');
posttrig            = ft_getopt(cfg, 'posttrig');
saveToDisk            = ft_getopt(cfg, 'saveData', 'no');
outputName          = ft_getopt(cfg, 'outputName', 'preproc');
resampleFs          = ft_getopt(cfg, 'resampleFs');
hpfreq              = ft_getopt(cfg, 'hpfreq');
lpfreq              = ft_getopt(cfg, 'lpfreq');
notchfreq           = ft_getopt(cfg, 'notchfreq');
filttype            = ft_getopt(cfg, 'filttype');
reref               = ft_getopt(cfg, 'reref', 'no');
refelec             = ft_getopt(cfg, 'refelec', 'all');
refmethod           = ft_getopt(cfg, 'refmethod', 'avg');
removechans         = ft_getopt(cfg, 'removechans', 'no');
channels2remove     = ft_getopt(cfg, 'channels2remove');
dataset             = ft_getopt(cfg, 'dataset');
hdrfile             = ft_getopt(cfg, 'hdrfile');
overwrite           = ft_getopt(cfg, 'overwrite', 'no');
interpolate         = ft_getopt(cfg, 'interpolate', 'no');
interpMethod        = ft_getopt(cfg, 'interpMethod', 'average');
quiet               = ft_getopt(cfg, 'quiet', 'no');
waveletThresh       = ft_getopt(cfg, 'waveletThresh', 'no');
channels            = ft_getopt(cfg, 'channels');
chanindx            = ft_getopt(cfg, 'chanindx');

quiet = strcmpi(quiet, 'yes') || isequal(quiet, true);

%% decide where the data comes from (raw dataset vs. subject folder)
if ~isempty(dataset) && ~isempty(hdrfile)
    if ~quiet
        fprintf('running with raw \n \t dataset: %s and \n \t hdrfile: %s \n ', ...
            dataset, hdrfile)
        fprintf('**********************************************************\n')
        fprintf('\n')
    end
    hasdata = 1;
    subjectdata = struct();
    saveSubjectData = 'no';
    if strcmpi(saveToDisk, 'yes')
        warning('data can not be saved when given dataset and hdrfile inputs, not saving ... ')
        saveToDisk = 'no';
    end
else
    if isempty(currSubject)
        error('no dataset and hdrfile given, while no currSubject is known')
    end
    %     fprintf('running with subject.mat file of %s ', currSubject)
    hasdata = 0;
    saveSubjectData = 'yes';
end

%% load subject info (when running on a subject folder)
if ~hasdata % check whether data needs to be loaded from subject.mat file

    eval(pathsFcn) % get paths necessary to run function

    if ~quiet; disp(currSubject); end

    % skip if the output already exists
    if strcmpi(overwrite, 'no') && strcmpi(saveToDisk, 'yes') && ...
            exist(fullfile(PATHS.SUBJECTS, currSubject, 'preproc', [currSubject '_' outputName '.mat']), 'file')
        % Nothing is loaded, run or changed on this path: the existing
        % Subject.mat (from the run that produced this output) stays as it
        % is, and subjectdata is not assigned (callers only use data). The
        % driver's syncSubjectSummary afterwards just re-reads that
        % Subject.mat from disk and merges it into SubjectSummary.mat.
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end


    % Try to load in individuals Subject.mat. If unknown --> throw error.
    try
        load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'], 'subjectdata')
    catch
        error('Subject.mat file not found')
    end

    if ~quiet; fprintf('\t Setting up for preprocessing ... '); end

    datasets = subjectdata.PATHS.DATAFILES;
    hdrfiles = subjectdata.PATHS.HDRFILES;
    if ~quiet; fprintf('done! \n'); end
end
if hasdata
    datasets = cellstr(dataset);
    hdrfiles = cellstr(hdrfile);
end
nParts = numel(datasets);

%% read header and select channels
% The parts of a session have the same channels and sampling rate (checked
% by MATCHRAWFILES), so the header of the first part is used for all.

% NOTE on channel selection: the data itself is selected by cfg.channel (step
% 1 below). A single entry such as {'EEG'} is handed to FieldTrip as a channel
% group: ft_channelselection resolves it via ft_chantype to the actual EEG
% electrodes, so other channels such as EXG*/Status are left out of the data.
% In that case, hdr still describes ALL channels; it is only used for the
% layout and the sampling rate. With more than one entry, the matching channel
% indices are looked up (CHECKCHANNELS) and hdr is restricted to those.
% chanindx only restricts hdr: the cfg.chanindx set below is not read by
% ft_preprocessing.
hdrfile = hdrfiles{1};
if ~isempty(chanindx)
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
elseif length(channels)>1
    chanindx = checkChannels(hdrfile, channels);
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
else
    evalc('hdr = ft_read_header(hdrfile);');
    chanindx = 1:length(hdr.label);
end

% channels to leave out when reading the data in (removeChannels sets
% subjectdata.flaggedChannels as a column cell array)
removingChans = strcmpi(removechans, 'yes');
if removingChans && ~isempty(channels2remove)
    if ischar(channels2remove)
        channels2remove = {channels2remove};
    end
    if isfield(subjectdata, 'flaggedChannels') && ~isempty(subjectdata.flaggedChannels)
        warning('overwriting subjectdata.flaggedChannels with given cfg.channels2remove')
    end
    subjectdata.flaggedChannels = channels2remove(:);
end


subjectdata.cfgs.(outputName) = cfg; % save used config file in subjectdata
subjectdata.trialfun = trialfun;

neighbours = [];
chanCfg = [];

% only read in EEG data (without possible removed channels)
if removingChans && isfield(subjectdata, 'flaggedChannels') && ~isempty(subjectdata.flaggedChannels)

    % neighbours (for interpolating the removed channels later on) have to
    % be determined while the removed channels are still part of the layout
    layout = getLayoutType(hdr);

    nbCfg = [];
    nbCfg.channel = channels;
    nbCfg.layout = layout;
    nbCfg.method = 'triangulation';
    nbCfg.feedback = 'no';
    evalc('neighbours = ft_prepare_neighbours(nbCfg);');

    if ~quiet
        fprintf(['\n \t\t skipping following channel(s): ' ...
        repmat('%s, ', 1,length(subjectdata.flaggedChannels))], subjectdata.flaggedChannels{:});
    end
    chanCfg.channel = cat(2, channels{:}, strcat('-',subjectdata.flaggedChannels'));
else
    chanCfg.channel = channels;
end
chanCfg.chanindx = chanindx;

interpolating = strcmpi(interpolate, 'yes') && isfield(subjectdata, 'flaggedChannels') && ...
    ~isempty(subjectdata.flaggedChannels);
if interpolating && isempty(neighbours)
    error('preprocResample:interpolateWithoutRemove', ...
        ['cfg.interpolate is ''yes'' but cfg.removechans is not: the flagged ' ...
        'channels were never left out of the data (and no neighbours were ' ...
        'determined), so there is nothing to interpolate. Set cfg.removechans ' ...
        'to ''yes'' as well.'])
end

%% steps 1-6 for every part
% Every part is read in, interpolated, resampled, filtered, rereferenced
% and wavelet thresholded on its own, so no filter runs across the place
% where two parts meet. A part that can't be read is dropped; the subject
% is only removed when no part is left.
partOptions = struct('chanCfg', chanCfg, 'interpolating', interpolating, ...
    'missingChannels', [], 'neighbours', {neighbours}, 'interpMethod', interpMethod, ...
    'resampleFs', resampleFs, 'hpfreq', hpfreq, 'lpfreq', lpfreq, 'notchfreq', notchfreq, ...
    'filttype', filttype, 'reref', reref, 'refelec', {refelec}, 'refmethod', refmethod, ...
    'waveletThresh', waveletThresh, 'checkComplete', ~hasdata, 'quiet', quiet);
if interpolating
    partOptions.missingChannels = subjectdata.flaggedChannels';
end

dataParts   = cell(1, nParts);
partFailure = cell(1, nParts);
for k = 1:nParts
    if ~quiet && nParts > 1
        [~, partName, partExt] = fileparts(datasets{k});
        fprintf('\t part %d of %d: %s%s\n', k, nParts, partName, partExt)
    end
    try
        dataParts{k} = preprocessPart(datasets{k}, hdrfiles{k}, partOptions);
    catch ME
        if ~strcmp(ME.identifier, 'preprocResample:partFailed')
            rethrow(ME)
        end
        partFailure{k} = ME.message;
        if ~quiet; fprintf('\n \t \t %s, dropping this part ... \n', ME.message); end
    end
end
kept = ~cellfun(@isempty, dataParts);

% keep the record of the raw files up to date. The gap before a part is
% counted from the previous part that is kept, so a dropped part makes the
% gap longer by its own length.
partGaps = zeros(1, sum(kept));
if isfield(subjectdata, 'rawFiles')
    usedIndx = find(strcmp({subjectdata.rawFiles.status}, 'used'));
    partGaps = effectiveGaps(subjectdata.rawFiles(usedIndx), kept);
    for k = find(~kept)
        subjectdata.rawFiles(usedIndx(k)).status = 'dropped';
        subjectdata.rawFiles(usedIndx(k)).reason = partFailure{k};
        subjectdata.rawFiles(usedIndx(k)).gapToPrevious = NaN;
    end
    keptIndx = usedIndx(kept);
    for k = 1:numel(keptIndx)
        subjectdata.rawFiles(keptIndx(k)).gapToPrevious = partGaps(k);
    end
    subjectdata.PATHS.DATAFILES = datasets(kept);
    subjectdata.PATHS.HDRFILES  = hdrfiles(kept);
    subjectdata.nRawFilesUsed   = sum(kept);
end

if ~any(kept)
    if hasdata
        error('could not read dataset %s: %s', dataset, partFailure{1})
    end
    if nParts == 1
        reason = ['preprocessing - ' partFailure{1}];
    else
        reasons = cell(1, nParts);
        for k = 1:nParts
            [~, partName, partExt] = fileparts(datasets{k});
            reasons{k} = sprintf('%s%s: %s', partName, partExt, partFailure{k});
        end
        reason = ['preprocessing - no readable part (' strjoin(reasons, '; ') ')'];
    end
    subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, reason, quiet);
    data = [];
    return
end
datasets  = datasets(kept);
hdrfiles  = hdrfiles(kept);
dataParts = dataParts(kept);
nParts    = numel(datasets);

if interpolating
    % keep a record of ALL channels interpolated so far (also by other
    % steps, e.g. removeChannels), not just those of this call
    interpolatedBefore = {};
    if isfield(subjectdata, 'interpolatedChannels') && ~isempty(subjectdata.interpolatedChannels)
        interpolatedBefore = cellstr(subjectdata.interpolatedChannels);
    end
    subjectdata.interpolatedChannels = unique( ...
        [interpolatedBefore(:); subjectdata.flaggedChannels(:)], 'stable');
end
if ~isempty(resampleFs)
    subjectdata.resampleFs = resampleFs;
end
if strcmpi(reref, 'yes')
    subjectdata.refElec = refelec;
    subjectdata.refMethod = refmethod;
end

%% stitch the parts into one recording
% The parts are put after each other on one time line, with the real gap
% between them (the time between the end of a part and the start of the
% next one, from the file headers) as NaN samples in between. When parts
% were dropped above, the gap runs from the last part that is kept. A gap
% is not made longer than the longest trial (see below). Trials are cut
% from this stitched recording, so a trial that crosses the place where two
% parts meet is not cut off there; it holds data of both parts (and NaN for
% a part of it if the parts were not contiguous).
fs = dataParts{1}.fsample;
partLen = cellfun(@(d) size(d.trial{1}, 2), dataParts);

% what the trial function needs to know about the data it cuts
trialCfg = [];
if ~isempty(trialfun)
    if nParts == 1
        trialCfg.dataset = datasets{1};
        trialCfg.headerfile = hdrfiles{1};
    else
        trialCfg.dataset = datasets;
        trialCfg.headerfile = hdrfiles;
    end
    trialCfg.trialdef.pretrig = pretrig; % when to make a cut before stim presentation
    trialCfg.trialdef.posttrig = posttrig; % when to make a cut after stim presentation
    if isempty(resampleFs)
        trialCfg.Fs = hdr.Fs;
    else
        trialCfg.Fs = resampleFs;
    end
end

% The gap before every part is the real gap, but not longer than the
% longest trial the trial function returns: a trial can't reach further
% than that into the gap. To know that length, the trial function is run
% once on the recording with the real gaps (only the positions of the
% trials depend on the gaps, not their length). Without a trial function
% there are no trials to protect and the parts are joined without padding.
gapSamples = zeros(1, nParts);
trl = [];
trlKnown = false;
if isfield(subjectdata, 'rawFiles') && nParts > 1 && ~isempty(trialfun) && any(partGaps(2:end) > 0)
    realGaps = round(partGaps * fs);
    realGaps(1) = 0;
    realOffsets = zeros(1, nParts);
    for k = 2:nParts
        realOffsets(k) = realOffsets(k-1) + partLen(k-1) + realGaps(k);
    end
    trialCfg.partOffsets = realOffsets;
    trl = feval(trialfun, trialCfg);
    if isempty(trl)
        longestTrial = 0;       % no trials: the subject is removed below
    else
        longestTrial = max(trl(:, 2) - trl(:, 1) + 1);
    end
    gapSamples = min(realGaps, longestTrial);
    % the trl is also valid for the final offsets if no gap was shortened
    trlKnown = ~isempty(trl) && isequal(gapSamples, realGaps);
end
partOffsets = zeros(1, nParts);
for k = 2:nParts
    partOffsets(k) = partOffsets(k-1) + partLen(k-1) + gapSamples(k);
end

data = dataParts{1};
if nParts > 1
    nChans = size(data.trial{1}, 1);
    pieces = cell(1, 2*nParts - 1);
    pieces{1} = data.trial{1};
    for k = 2:nParts
        if ~isequal(dataParts{k}.label, data.label)
            error('preprocResample:labelsDiffer', 'the channels of the parts of %s differ', currSubject)
        end
        pieces{2*k - 2} = nan(nChans, gapSamples(k));
        pieces{2*k - 1} = dataParts{k}.trial{1};
    end
    data.trial{1}      = cat(2, pieces{:});
    nTotal             = size(data.trial{1}, 2);
    data.time{1}       = data.time{1}(1) + (0:nTotal-1) / fs;
    data.sampleinfo    = data.sampleinfo(1, 1) + [0 nTotal-1];
end
clear dataParts pieces

%% 7) cut data into trials based on trialfun
% Your trialfun detects the epochs in your data and adds them to a trl
% variable. It's very important that if you've resampled your data, you use your
% updated sample info. See for example trialfunYOUthConnectivity. In this
% trialfun the event codes (and sample info) are read in from the raw EEG
% files and converted to resampled values. These are used in ft_redefinetrial
% to redefine the trialstructure of the data file. For a stitched recording,
% the trialfun gets all parts and their position in the stitched data (cfg.partOffsets).
if ~isempty(trialfun)
    if ~quiet; fprintf('\t Redefining trialstructure based on %s ... \n', trialfun); end

    cfg = trialCfg;
    if nParts > 1
        cfg.partOffsets = partOffsets;
    end

    % ft_definetrial would throw an error ("no trials were defined") on an
    % empty trl, so without this check a subject without trials would crash
    % the run instead of being removed.
    if ~trlKnown
        trl = feval(trialfun, cfg);
    end

    if isempty(trl)
        data = [];
        if hasdata
            % no subject folder to remove
            warning('no trials found in dataset %s', strjoin(datasets, ', '))
            return
        end
        if ~quiet; fprintf('\n \t \t no trials found, removing subject and continuing ... \n'); end
        subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, ...
            'preprocessing - no trials found', quiet);
        return
    end
    cfg.trl = trl;

    if ~quiet
        trlCount = showTrialAmount(cfg);
    else
        evalc('trlCount = showTrialAmount(cfg);');
    end
    subjectdata.nTrialsPreproc = sum(trlCount);

    % count the trials per part, and the trials that hold the place where
    % two parts meet (edge trials; with gap: part of the trial is NaN)
    partEnd = partOffsets + partLen;
    triggerSample = trl(:, 1) - trl(:, 3);
    nTrialsPart = zeros(1, nParts);
    for k = 1:nParts
        nTrialsPart(k) = sum(triggerSample > partOffsets(k) & triggerSample <= partEnd(k));
    end
    isEdge = false(size(trl, 1), 1);
    isEdgeGap = false(size(trl, 1), 1);
    for k = 2:nParts
        spans = trl(:, 1) <= partEnd(k-1) + gapSamples(k) & trl(:, 2) > partEnd(k-1);
        isEdge = isEdge | spans;
        if gapSamples(k) > 0
            isEdgeGap = isEdgeGap | spans;
        end
    end
    subjectdata.nEdgeTrials    = sum(isEdge);
    subjectdata.nEdgeTrialsGap = sum(isEdgeGap);
    if isfield(subjectdata, 'rawFiles')
        usedIndx = find(strcmp({subjectdata.rawFiles.status}, 'used'));
        [subjectdata.rawFiles.nTrials] = deal(NaN);
        for k = 1:nParts
            subjectdata.rawFiles(usedIndx(k)).nTrials = nTrialsPart(k);
        end
        subjectdata.nRawFilesWithTrials = sum(nTrialsPart > 0);
    end
    if ~quiet && nParts > 1
        fprintf('\t\t %d trials hold the place where two parts meet (%d with a gap)\n', ...
            subjectdata.nEdgeTrials, subjectdata.nEdgeTrialsGap)
    end

    redefCfg = [];
    redefCfg.trl = trl;
    evalc('data = ft_redefinetrial(redefCfg, data);');


end

%% save data
if strcmpi(saveToDisk, 'yes')
    if ~quiet
        saveData(subjectdata, data, outputName);              % save both data and subjectdata to the drive
    else
        evalc('saveData(subjectdata, data, outputName);');              % save both data and subjectdata to the drive
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        saveData(subjectdata);              % save subjectdata to the drive
    else
        evalc('saveData(subjectdata);');              % save subjectdata to the drive
    end
end

end

%% helper functions
function subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, reason, quiet)
% Marks the subject as having no preprocessed trials, saves its subjectdata
% (REMOVINGSUBJECTS reloads it from disk, so it has to be saved first), and
% moves the subject to PATHS.REMOVED. Returns the updated subjectdata.
subjectdata.nTrialsPreproc = 0;

if ~quiet
    saveData(subjectdata)
else
    evalc('saveData(subjectdata);');
end

cfg = [];
cfg.pathsFcn = pathsFcn;
removingSubjects(cfg, currSubject, reason)
end


function data = preprocessPart(dataset, hdrfile, o)
% Steps 1-6 of PREPROCRESAMPLE for one raw file: read in, interpolate,
% resample, filter, rereference and wavelet threshold. Returns the data
% as one continuous trial. For a file that can't be read in (incomplete or
% truncated), the error 'preprocResample:partFailed' is thrown, with the
% reason as its message; other errors are passed on.
quiet = o.quiet;

% an incomplete bdf file has no (or only one) line break in it
if o.checkComplete
    fid = fopen(dataset, 'r');
    if fid < 0
        error('could not open dataset %s', dataset)
    end
    fgetl(fid);
    ln2 = fgetl(fid);
    fclose(fid);
    if ln2 == -1
        error('preprocResample:partFailed', 'incomplete bdf file')
    end
end

%% 1) read in data
if ~quiet; fprintf('\t loading in data ... '); end

cfg = o.chanCfg;
cfg.dataset = dataset;
cfg.headerfile = hdrfile;
cfg.continuous = 'yes';

% With cfg.dataset set and no data input, ft_preprocessing loads the selected
% channels from disk as continuous data, so this is the step that actually
% reads the file. A corrupt or truncated file makes it error; the part is
% then dropped instead of the whole run crashing.
try
    evalc('data = ft_preprocessing(cfg);');
catch ME
    if ~o.checkComplete
        % running on a raw dataset: no subject folder, so just pass the error on
        rethrow(ME)
    end
    if contains(ME.message, 'One or more output arguments not assigned during call to "read_24bit".')
        error('preprocResample:partFailed', 'truncated bdf file (read_24bit error)')
    else
        error('preprocResample:partFailed', '%s', ME.message)
    end
end

if ~quiet; fprintf('done! \n'); end

%% 2) interpolate removed channels
if o.interpolating
    if ~quiet
        fprintf(['\t the following channels will be interpolated ... ', ...
            repmat('%s, ',1, length(o.missingChannels))], o.missingChannels{:})
    end

    cfg = [];
    cfg.missingchannel = o.missingChannels;
    cfg.method = o.interpMethod;
    cfg.neighbours = o.neighbours;
    evalc('data = ft_channelrepair(cfg, data);');

    if ~quiet; fprintf('done! \n'); end
end

%% 3) resample (if a resampleFs is given)
if ~isempty(o.resampleFs)

    if ~quiet; fprintf('\t Resampling data from %s to %s ... ', num2str(data.fsample), num2str(o.resampleFs)); end
    cfg = [];
    cfg.resamplefs  = o.resampleFs;
    % cfg.detrend     = 'yes';
    evalc('data = ft_resampledata(cfg, data);');

    if ~quiet; fprintf('done! \n'); end
end

%% 4) filter data (if a hpfreq, lpfreq, or notchfreq is given)
% See FILTEREEGDATA for more info
if ~(isempty(o.hpfreq) && isempty(o.lpfreq) && isempty(o.notchfreq))

    cfg = [];
    cfg.hpfreq      = o.hpfreq;
    cfg.lpfreq      = o.lpfreq;
    cfg.notchfreq   = o.notchfreq;
    cfg.filttype    = o.filttype;

    if ~quiet
        data = filterEEGData(cfg, data);
    else
        evalc('data = filterEEGData(cfg, data);');
    end
end

%% 5) rereference
if strcmpi(o.reref, 'yes')
    if iscell(o.refelec)
        refelecStr = strjoin(o.refelec, ', ');
    else
        refelecStr = num2str(o.refelec);
    end
    if ~quiet; fprintf('\t rereferencing to %s electrode ... ', refelecStr); end

    cfg = [];
    cfg.reref = 'yes';
    cfg.refchannel = o.refelec;
    cfg.refmethod = o.refmethod;
    evalc('data = ft_preprocessing(cfg, data);');

    if ~quiet; fprintf('done!\n'); end
end

%% 6) wavelet thresholding
if strcmpi(o.waveletThresh, 'yes')
    if ~quiet; fprintf('\t Wavelet thresholding, based on HAPPE_v3 ...'); end

    wavFam = 'bior4.4' ;
    if data.fsample > 500
        wavLvl = 10;
    elseif data.fsample > 250 && data.fsample <= 500
        wavLvl = 9;
    elseif data.fsample <=250
        wavLvl = 8;
    end

    ThresholdRule = 'Hard' ;

    artfcs = wdenoise(data.trial{1}', wavLvl, ...
        'Wavelet', wavFam, 'DenoisingMethod', 'Bayes', 'ThresholdRule', ...
        ThresholdRule, 'NoiseEstimate', 'LevelDependent')' ;

    preEEG = reshape(data.trial{1}, size(data.trial{1},1), []) ;
    postEEG = preEEG - artfcs;
    data.trial{1} = postEEG;
    if ~quiet; fprintf('done! \n'); end
end
end


function gaps = effectiveGaps(partFiles, kept)
% Gap (s) before every kept part, counted from the previous kept part.
% partFiles are the raw file records of the parts, in order, and kept says
% which of them were read. A dropped part adds its own length and the gap
% before it to the gap of the next kept part. The first kept part gets NaN.
gaps = nan(1, numel(kept));
acc = 0;
haveKept = false;
for k = 1:numel(kept)
    g = partFiles(k).gapToPrevious;
    if isnan(g)
        g = 0;
    end
    if kept(k)
        if haveKept
            gaps(k) = acc + g;
        end
        acc = 0;
        haveKept = true;
    elseif haveKept
        acc = acc + g + partFiles(k).duration;
    end
end
gaps = gaps(kept);
end
