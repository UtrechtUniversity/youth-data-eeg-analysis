function [ data, subjectdata ] = bv_preprocResample(cfg)
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
% Can be run in two ways: (1) on a subject created by
% BV_CREATESUBJECTFOLDERS_NEWSTRUCT (``cfg.currSubject``), reading subject
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
%     cfg.dataset (str): Raw dataset filename. Required, together with
%         ``cfg.hdrfile``, when ``cfg.currSubject`` is not used.
%     cfg.hdrfile (str): Header filename. See ``cfg.dataset``.
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
%         BV_CHECKCHANNELS and only those are read from the header.
%         Defaults to all channels.
%     cfg.chanindx (numeric, optional): Channel indices to read in. Takes
%         precedence over ``cfg.channels`` for choosing which channels
%         are read from the header.
%     cfg.trialfun (str, optional): Filename of the trial function used to
%         cut the data into trials (must be on the MATLAB path, see
%         TRIALFUN_YOUTH_CONNECTIVITY). Leave empty to skip trial cutting.
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
%         BV_FILTEREEGDATA.
%     cfg.reref (str, optional): Whether to rereference the data (``'yes'``
%         or ``'no'``). Defaults to ``'no'``.
%     cfg.refelec (str or cell array of str, optional): Rereference
%         channel(s); ``'all'`` is a common average reference. Defaults to
%         ``'all'``.
%     cfg.refmethod (str, optional): Rereference method, passed to
%         FT_PREPROCESSING as ``cfg.refmethod``. Defaults to ``'avg'``.
%     cfg.removechans (str, optional): Whether to skip the channels listed
%         in ``subjectdata.flaggedChannels`` (set by BV_REMOVECHANNELS)
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
%         the subject was removed (via REMOVINGSUBJECTS) because of an
%         incomplete/truncated file, a read error, or no trials found.
%     subjectdata (struct): Updated subject info (not assigned when
%         returning early because the output already exists).
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
%     cfg.trialfun    = 'trialfun_YOUth_connectivity';
%     data = bv_preprocResample(cfg);
%     ```

%% get options
currSubject         = ft_getopt(cfg, 'currSubject');
pathsFcn            = ft_getopt(cfg, 'pathsFcn', 'setPaths');
trialfun            = ft_getopt(cfg, 'trialfun');
pretrig             = ft_getopt(cfg, 'pretrig');
posttrig            = ft_getopt(cfg, 'posttrig');
saveData            = ft_getopt(cfg, 'saveData', 'no');
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
    if strcmpi(saveData, 'yes')
        warning('data can not be saved when given dataset and hdrfile inputs, not saving ... ')
        saveData = 'no';
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
    if strcmpi(overwrite, 'no') && strcmpi(saveData, 'yes') && ...
            exist(fullfile(PATHS.SUBJECTS, currSubject, 'preproc', [currSubject '_' outputName '.mat']), 'file')
        % Nothing is loaded, run or changed on this path: the existing
        % Subject.mat (from the run that produced this output) stays as it
        % is, and subjectdata is not assigned (callers only use data). The
        % driver's bv_syncSubjectSummary afterwards just re-reads that
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

    hdrfile = subjectdata.PATHS.HDRFILE;
    dataset = subjectdata.PATHS.DATAFILE;

    % an incomplete bdf file has no (or only one) line break in it
    fid = fopen(dataset, 'r');
    if fid < 0
        error('could not open dataset %s', dataset)
    end
    fgetl(fid);
    ln2 = fgetl(fid);
    fclose(fid);

    if ln2 == -1
        if ~quiet; fprintf('\n \t \t bdf file incomplete, removing subject and continueing ... \n'); end
        subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, ...
            'preprocessing - incomplete bdf file', quiet);
        data = [];
        return
    end
    if ~quiet; fprintf('done! \n'); end
end

%% read header and select channels

% NOTE on channel selection: the data itself is selected by cfg.channel (step
% 1 below). A single entry such as {'EEG'} is handed to FieldTrip as a channel
% group: ft_channelselection resolves it via ft_chantype to the actual EEG
% electrodes, so other channels such as EXG*/Status are left out of the data.
% In that case, hdr still describes ALL channels; it is only used for the
% layout and the sampling rate. With more than one entry, the matching channel
% indices are looked up (BV_CHECKCHANNELS) and hdr is restricted to those.
% chanindx only restricts hdr: the cfg.chanindx set below is not read by
% ft_preprocessing.
if ~isempty(chanindx)
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
elseif length(channels)>1
    chanindx = bv_checkChannels(hdrfile, channels);
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
else
    evalc('hdr = ft_read_header(hdrfile);');
    chanindx = 1:length(hdr.label);
end

% channels to leave out when reading the data in (bv_removeChannels sets
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

%% 1) read in data
if ~quiet; fprintf('\t loading in data ... '); end

cfg = [];
neighbours = [];
layout = [];

% only read in EEG data (without possible removed channels)
if removingChans && isfield(subjectdata, 'flaggedChannels') && ~isempty(subjectdata.flaggedChannels)

    % neighbours (for interpolating the removed channels later on) have to
    % be determined while the removed channels are still part of the layout
    layout = bv_getLayoutType(hdr);

    cfg.channel = channels;
    cfg.layout = layout;
    cfg.method = 'triangulation';
    cfg.feedback = 'no';
    evalc('neighbours = ft_prepare_neighbours(cfg);');

    if ~quiet
        fprintf(['\n \t\t skipping following channel(s): ' ...
        repmat('%s, ', 1,length(subjectdata.flaggedChannels))], subjectdata.flaggedChannels{:});
    end
    cfg = [];
    cfg.channel = cat(2, channels{:}, strcat('-',subjectdata.flaggedChannels'));
else
    cfg.channel = channels;
end

cfg.dataset = dataset;
cfg.headerfile = hdrfile;
cfg.continuous = 'yes';
cfg.chanindx = chanindx;

%% read the raw file into memory
% With cfg.dataset set and no data input, ft_preprocessing loads the selected
% channels from disk as continuous data, so this is the step that actually
% reads the file. A corrupt or truncated file makes it error; the subject is
% then removed instead of the whole run crashing.
try
    evalc('data = ft_preprocessing(cfg);');
catch ME
    if hasdata
        % no subject folder to remove, so just pass the error on
        rethrow(ME)
    end

    if contains(ME.message, 'One or more output arguments not assigned during call to "read_24bit".')
        if ~quiet; fprintf('\n \t \t bdf file truncated, removing subject and continuing ... \n'); end
        reason = 'preprocessing - truncated bdf file (read_24bit error)';
    else
        if ~quiet; fprintf('\n \t \t error when reading file, removing subject and continuing ... \n'); end
        reason = ['preprocessing - ' ME.message];
    end
    subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, reason, quiet);

    data = [];
    return
end

if ~quiet; fprintf('done! \n'); end

%% 2) interpolate removed channels
if strcmpi(interpolate, 'yes')
    if isfield(subjectdata, 'flaggedChannels') && ~isempty(subjectdata.flaggedChannels)
        if isempty(neighbours)
            error('bv_preprocResample:interpolateWithoutRemove', ...
                ['cfg.interpolate is ''yes'' but cfg.removechans is not: the flagged ' ...
                'channels were never left out of the data (and no neighbours were ' ...
                'determined), so there is nothing to interpolate. Set cfg.removechans ' ...
                'to ''yes'' as well.'])
        end
        if ~quiet
            fprintf(['\t the following channels will be interpolated ... ', ...
                repmat('%s, ',1, length(subjectdata.flaggedChannels))], subjectdata.flaggedChannels{:})
        end

        cfg = [];
        cfg.missingchannel = subjectdata.flaggedChannels';
        cfg.method = interpMethod;
        cfg.neighbours = neighbours;
        cfg.layout = layout;
        evalc('data = ft_channelrepair(cfg, data);');

        % keep a record of ALL channels interpolated so far (also by other
        % steps, e.g. bv_removeChannels), not just those of this call
        interpolatedBefore = {};
        if isfield(subjectdata, 'interpolatedChannels') && ~isempty(subjectdata.interpolatedChannels)
            interpolatedBefore = cellstr(subjectdata.interpolatedChannels);
        end
        subjectdata.interpolatedChannels = unique( ...
            [interpolatedBefore(:); subjectdata.flaggedChannels(:)], 'stable');

        if ~quiet; fprintf('done! \n'); end
    end
end

%% 3) resample (if a resampleFs is given)
if ~isempty(resampleFs)

    if ~quiet; fprintf('\t Resampling data from %s to %s ... ', num2str(data.fsample), num2str(resampleFs)); end
    cfg = [];
    cfg.resamplefs  = resampleFs;
    % cfg.detrend     = 'yes';
    evalc('data = ft_resampledata(cfg, data);');
    subjectdata.resampleFs = resampleFs;

    if ~quiet; fprintf('done! \n'); end
end

%% 4) filter data (if a hpfreq, lpfreq, or notchfreq is given)
% See BV_FILTEREEGDATA for more info
if ~(isempty(hpfreq) && isempty(lpfreq) && isempty(notchfreq))

    cfg = [];
    cfg.hpfreq      = hpfreq;
    cfg.lpfreq      = lpfreq;
    cfg.notchfreq   = notchfreq;
    cfg.filttype    = filttype;

    if ~quiet
        data = bv_filterEEGdata(cfg, data);
    else
        evalc('data = bv_filterEEGdata(cfg, data);');
    end
end

%% 5) rereference
if strcmpi(reref, 'yes')
    if iscell(refelec)
        refelecStr = strjoin(refelec, ', ');
    else
        refelecStr = num2str(refelec);
    end
    if ~quiet; fprintf('\t rereferencing to %s electrode ... ', refelecStr); end

    cfg = [];
    cfg.reref = 'yes';
    cfg.refchannel = refelec;
    cfg.refmethod = refmethod;
    evalc('data = ft_preprocessing(cfg, data);');
    subjectdata.refElec = refelec;
    subjectdata.refMethod = refmethod;

    if ~quiet; fprintf('done!\n'); end
end

%% 6) wavelet thresholding
wavelet_thresholding = strcmpi(waveletThresh, 'yes');
if wavelet_thresholding
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

%% 7) cut data into trials based on trialfun
% Your trialfun detects the epochs in your data and adds them to a trl
% variable. It's very important that if you've resampled your data, you use your
% updated sample info. See for example trialfun_YOUth_connectivity. In this
% trialfun the event codes (and sample info) are read in from the raw EEG
% files and converted to resampled values. These are used in
% ft_redefinetrial to redefine the trialstructure of the data file
if ~isempty(trialfun)
    if ~quiet; fprintf('\t Redefining trialstructure based on %s ... \n', trialfun); end

    cfg = [];
    cfg.dataset = dataset;
    cfg.headerfile = hdrfile;
    cfg.trialfun = trialfun;
    cfg.trialdef.pretrig = pretrig; % when to make a cut before stim presentation
    cfg.trialdef.posttrig = posttrig; % when to make a cut after stim presentation
    if isempty(resampleFs)
        cfg.Fs = hdr.Fs;
    else
        cfg.Fs = resampleFs;
    end

    % NOTE: trialfun is run twice on purpose: once here, as a cheap check
    % whether it finds any trials, and again inside ft_definetrial below.
    % ft_definetrial throws an error ("no trials were defined") on an empty
    % trl, so without this check a subject without trials would crash the
    % run instead of being removed.
    trl = feval(trialfun, cfg);

    if isempty(trl)
        data = [];
        if hasdata
            % no subject folder to remove
            warning('no trials found in dataset %s', dataset)
            return
        end
        if ~quiet; fprintf('\n \t \t no trials found, removing subject and continuing ... \n'); end
        subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, ...
            'preprocessing - no trials found', quiet);
        return
    else
        evalc('cfg = ft_definetrial(cfg);');
    end

    if ~quiet
        trlCount = bv_showTrialAmount(cfg);
    else
        evalc('trlCount = bv_showTrialAmount(cfg);');
    end
    subjectdata.nTrialsPreproc = sum(trlCount);
    evalc('data = ft_redefinetrial(cfg, data);');


end

%% save data
if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);              % save both data and subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata, data, outputName);');              % save both data and subjectdata to the drive
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);              % save subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata);');              % save subjectdata to the drive
    end
end

end

%% helper function
function subjectdata = removeSubject(subjectdata, currSubject, pathsFcn, reason, quiet)
% Marks the subject as having no preprocessed trials, saves its subjectdata
% (REMOVINGSUBJECTS reloads it from disk, so it has to be saved first), and
% moves the subject to PATHS.REMOVED. Returns the updated subjectdata.
subjectdata.nTrialsPreproc = 0;

if ~quiet
    bv_saveData(subjectdata)
else
    evalc('bv_saveData(subjectdata);');
end

cfg = [];
cfg.pathsFcn = pathsFcn;
removingSubjects(cfg, currSubject, reason)
end
