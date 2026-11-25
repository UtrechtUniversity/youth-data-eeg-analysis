function [ connectivity ] = bv_calculatePLI(cfg, data)
% Calculates PLI values for specified frequency ranges.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Always required, since
%         the continuous data is read in again from the subject's raw file
%         (see ``cfg.preprocOptions``).
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         the clean-trial definitions (``data``). Required when no data is
%         provided.
%     cfg.saveData (str, optional): Whether to save output to disk
%         (``'yes'`` or ``'no'``). Subject.mat is saved whenever this
%         function runs, whatever this is set to. Defaults to ``'no'``.
%     cfg.outputName (str): Unique label for output file, its
%         ``subjectdata.PATHS`` entry, and this run's config in
%         ``subjectdata.cfgs``. Required when saving data.
%     cfg.ntrials (int or str, optional): Number of epochs to use. If more
%         clean epochs are available, that many are drawn at random; if
%         fewer, the subject is skipped (empty output). Defaults to
%         ``'all'``.
%     cfg.condition (str or numeric, optional): Condition (trigger) codes
%         to include, or ``'all'``. Defaults to ``'all'``.
%     cfg.freqBands (struct, optional): Fields are band labels, values are
%         ``[low high]`` Hz ranges used to band-pass filter the continuous
%         signal before PLI is computed for that band (matching the
%         cfg.freqBands convention used by bv_extractROIPower). Defaults to
%         the same bands as the power step: delta [1 3], theta [4 7],
%         alpha [8 12], beta [13 25], gamma [26 35], infantTheta [3 6],
%         infantAlpha [6 9], total [1 35]. Band order (and therefore column
%         order downstream) follows fieldnames(cfg.freqBands), i.e. the order
%         the fields were assigned in.
%     cfg.preprocOptions (struct, optional): FieldTrip ``cfg`` struct
%         passed to ``bv_preprocResample`` before PLI calculation.
%         Defaults to ``[]``.
%     cfg.triallength (int, optional): Epoch length in seconds. The clean
%         stretches of ``data`` are cut into epochs of this length with
%         BV_REDEFINETRIALLENGTH. Stretches shorter than this are
%         dropped; if none is long enough the function errors. When
%         omitted, the stretches of ``data`` themselves are used as epochs.
%     cfg.overlap (num, optional): Overlap between consecutive epochs as a
%         fraction (0-1, exclusive of 1). ``2/3`` of 3 s epochs gives a
%         new epoch every 1 s. Only used when ``cfg.triallength`` is set.
%         Defaults to ``0`` (no overlap).
%     cfg.cleanEpochs (str, optional): Whether to remove the noisy
%         epochs (``'yes'`` or ``'no'``). An epoch is noisy if any
%         artefact metric named in ``cfg.lims`` is above its limit; the
%         metrics are measured on every epoch of the broadband data and
%         an noisy epoch is removed for all frequency bands, like in
%         BV_CLEANDATA. With ``'no'`` every epoch is kept, except the
%         ones with missing (NaN) samples.
%         Defaults to ``'yes'``.
%     cfg.lims (struct): Thresholds above which an epoch is discarded: one
%         field per artefact metric (``abs``, ``flatline``, ``kurtosis``,
%         ``variance``, see BV_CLEANDATA). Required when
%         ``cfg.cleanEpochs`` is ``'yes'``; not used otherwise.
%     cfg.minEpochs (int, optional): Minimum number of epochs a subject
%         needs, counted after the condition selection and artefact
%         rejection. A subject with fewer makes the function error with
%         the numbers in the message, so the pipeline scripts remove it
%         (see REMOVINGSUBJECTS). ``[]`` means no minimum (a subject is
%         then only rejected when no epoch is left). Defaults to ``[]``.
%     cfg.keeptrials (str, optional): Whether to retain per-trial PLI values
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure containing
%         multiple trials. The epochs are cut from it (its signal is used
%         for the artefact check) and their ``sampleinfo`` and
%         ``trialinfo`` are used to cut the same epochs out of the re-read,
%         band-filtered data. If omitted, it is loaded from disk using
%         ``cfg.currSubject`` and ``cfg.inputName``.
%
% Besides the connectivity file, the numbers of epochs are stored in
% subjectdata: ``nEpochsPLI`` (epochs before the artefact check) and
% ``nCleanEpochsPLI`` (epochs left after it).
%
% Returns:
%     connectivity (struct): PLI connectivity structure with fields
%         ``plispctrm`` (chan x chan x freq, or chan x chan x trial x freq
%         when ``cfg.keeptrials`` is ``'yes'``), ``dimord``, ``freq``,
%         ``freqRng``, ``freqBands``, ``label``, and ``trialinfo``. Returns
%         empty (``[]``) if output already exists and ``cfg.overwrite`` is
%         ``'no'``.
%
% Example:
%     Calculate PLI for the theta band and save to disk:
%
%     ```matlab
%     cfg = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputName   = 'CLEANED';
%     cfg.outputName  = 'PLI_THETA';
%     cfg.saveData    = 'yes';
%     cfg.freqBands.theta = [4 7];
%     connectivity = bv_calculatePLI(cfg);
%     ```
%
%     Use 3 s epochs with a 1 s sliding window, and discard epochs
%     with artefacts:
%
%     ```matlab
%     cfg.triallength = 3;
%     cfg.overlap     = 2/3;
%     cfg.lims        = struct('abs', 250, 'kurtosis', 10);
%     connectivity = bv_calculatePLI(cfg);
%     ```

%% get options
ntrials         = ft_getopt(cfg, 'ntrials','all');
condition       = ft_getopt(cfg, 'condition', 'all');
currSubject     = ft_getopt(cfg, 'currSubject');
inputName       = ft_getopt(cfg, 'inputName');
saveData        = ft_getopt(cfg, 'saveData', 'no');
outputName      = ft_getopt(cfg, 'outputName');
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
triallength     = ft_getopt(cfg, 'triallength');
overlap         = ft_getopt(cfg, 'overlap', 0);
cleanEpochs     = ft_getopt(cfg, 'cleanEpochs', 'yes');
lims            = ft_getopt(cfg, 'lims');
minEpochs       = ft_getopt(cfg, 'minEpochs');
keeptrials      = ft_getopt(cfg, 'keeptrials', 'no');
quiet           = ft_getopt(cfg, 'quiet');
preprocOptions  = ft_getopt(cfg, 'preprocOptions', []);
overwrite       = ft_getopt(cfg, 'overwrite', 'no');

%% frequency bands
% Default bands, the same as in setOptions_netmet.m and as the defaults of
% bv_extractROIPower. We suggest to keep them in sync.
defaultFreqBands.delta       = [1 3];   % Hz
defaultFreqBands.theta       = [4 7];   % Hz
defaultFreqBands.alpha       = [8 12];  % Hz
defaultFreqBands.beta        = [13 25]; % Hz
defaultFreqBands.gamma       = [26 35]; % Hz
defaultFreqBands.infantTheta = [3 6];   % Hz
defaultFreqBands.infantAlpha = [6 9];   % Hz
defaultFreqBands.total       = [1 35];  % Hz

freqBands = ft_getopt(cfg, 'freqBands', defaultFreqBands);
freqLabel = fieldnames(freqBands);
freqRng   = struct2cell(freqBands);

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if isempty(currSubject)
    error('bv_calculatePLI: cfg.currSubject is required (the continuous data is read in again from the subject''s raw file)')
end
if strcmpi(saveData, 'yes') && isempty(outputName)
    error('bv_calculatePLI: cfg.outputName is required when cfg.saveData is ''yes''')
end
if strcmpi(cleanEpochs, 'yes') && isempty(lims)
    error('bv_calculatePLI: cfg.lims is required when cfg.cleanEpochs is ''yes''')
end

%% load in data (if necessary)
if nargin < 2
    if ~quiet; disp(currSubject); end
    eval(pathsFcn)

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        [subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);
        if ~check
            error('%s: input data not found', currSubject)
        end
    else
        evalc('[subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);');
        if ~check %#ok<NODEF>
            error('%s: input data not found', currSubject)
        end
    end

    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName)); end
                connectivity = [];
                return
            end
        end
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
else

    eval(pathsFcn)

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        [subjectdata, check] = bv_check4data(subjectFolderPath);
        if ~check
            error('%s: Subject.mat not found', currSubject)
        end
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
        if ~check
            error('%s: Subject.mat not found', currSubject)
        end
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
end

if ~quiet; fprintf('\t loading in original data ...'); end
cfg = preprocOptions;
cfg.currSubject = currSubject;
cfg.saveData = 'no';
cfg.trialfun = '';
evalc('origdata = bv_preprocResample(cfg);');
if ~quiet; fprintf('done \n'); end

% A recording stitched from raw files that were not directly after each
% other holds NaN samples where the gap was, and a NaN would spread through
% the filters below. The stretches in between are therefore filtered
% separately; stretches too short to hold an epoch are left out.
isMissing = any(isnan(origdata.trial{1}), 1);
if any(isMissing)
    change = diff([0, ~isMissing, 0]);
    first  = find(change == 1);
    last   = find(change == -1) - 1;
    if ~isempty(triallength)
        long  = (last - first + 1) >= round(triallength * origdata.fsample);
        first = first(long);
        last  = last(long);
    end
    cfg = [];
    cfg.trl = [first' last' zeros(numel(first), 1)] + [1 1 0] * (origdata.sampleinfo(1, 1) - 1);
    evalc('origdata = ft_redefinetrial(cfg, origdata);');
end

%% define the epochs and discard the artefact-contaminated ones
% Done once on the broadband data (the same signal the power step checks),
% so every frequency band uses the same epochs.
if quiet; quietStr = 'yes'; else; quietStr = 'no'; end

if ~isempty(triallength)
    cfgEpoch             = [];
    cfgEpoch.triallength = triallength;
    cfgEpoch.overlap     = overlap;
    cfgEpoch.quiet       = quietStr;
    epochData = bv_redefineTriallength(cfgEpoch, data);
else
    epochData = data;
end

keepEpoch = true(1, numel(epochData.trial));
if ~strcmpi(condition, 'all')
    keepEpoch = ismember(epochData.trialinfo(:,1), condition)';
end
if ~any(keepEpoch)
    error('bv_calculatePLI: no epochs found for the requested condition')
end
nEpochs = sum(keepEpoch);

% epochs with missing (NaN) samples are never usable, whether they are
% clean on their artefact levels or not
keepEpoch = keepEpoch & ~cellfun(@(t) any(isnan(t(:))), epochData.trial);

if strcmpi(cleanEpochs, 'yes')
    cfgArt          = [];
    cfgArt.analyses = fieldnames(lims);
    cfgArt.quiet    = quietStr;
    artefactdef     = bv_createArtefactStruct(cfgArt, epochData);
    [~, badEpoch]   = bv_findCleanTrials(artefactdef, lims);
    keepEpoch       = keepEpoch & ~badEpoch;
end
nCleanEpochs = sum(keepEpoch);

subjectdata.nEpochsPLI      = nEpochs;
subjectdata.nCleanEpochsPLI = nCleanEpochs;
if ~quiet; fprintf('\t %d of %d epochs are free of artefacts \n', nCleanEpochs, nEpochs); end

if nCleanEpochs == 0
    error('no clean epochs found')
end
if ~isempty(minEpochs) && nCleanEpochs < minEpochs
    error('too few clean epochs (%d, minimum %d)', nCleanEpochs, minEpochs)
end

epochSampleinfo = epochData.sampleinfo(keepEpoch, :);
epochTrialinfo  = epochData.trialinfo(keepEpoch, :);

if ~strcmpi(ntrials, 'all')
    if nCleanEpochs < ntrials
        if ~quiet; fprintf('\t not enough epochs found, skipping ... \n'); end
        connectivity = [];
        return
    end
    selected        = sort(randperm(nCleanEpochs, ntrials));
    epochSampleinfo = epochSampleinfo(selected, :);
    epochTrialinfo  = epochTrialinfo(selected, :);
    if ~quiet; fprintf('\t selecting %d epochs ... \n', ntrials); end
end
clear epochData artefactdef

%% calculate PLIs
for iFreq = 1:length(freqLabel)
    currFreq = freqLabel{iFreq};
    currFreqRng = freqRng{iFreq};
    if ~quiet; fprintf('\t filtering for %s ... ' , currFreq); end
    cfg = [];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = currFreqRng(2);
    cfg.lpinstabilityfix = 'reduce';
    cfg.hpfilter = 'yes';
    cfg.hpfreq = currFreqRng(1);
    cfg.hpinstabilityfix = 'reduce';
    evalc('origdata_filt = ft_preprocessing(cfg, origdata);');

    if ~quiet; fprintf('\t cutting out the epochs ... \n'); end
    cfg = [];
    cfg.trl = [epochSampleinfo, zeros(size(epochSampleinfo,1),1), epochTrialinfo];
    evalc('dataCut = ft_redefinetrial(cfg, origdata_filt);');

    if ~quiet; fprintf('\t calculating PLI ... '); end
    PLIs = PLI(dataCut.trial,1);
    PLIs = cat(3,PLIs{:});

    if strcmpi(keeptrials, 'yes')
        connectivity.plispctrm(:,:,:, iFreq) = PLIs;
        connectivity.dimord = 'chan_chan_trl_freq';
        connectivity.sampleinfo = dataCut.sampleinfo;
        connectivity.time = dataCut.time;
    else
        connectivity.plispctrm(:,:,iFreq) = mean(PLIs,3);
        connectivity.dimord = 'chan_chan_freq';
    end

    if ~quiet; fprintf('done!\n'); end
end

connectivity.freq      = freqLabel;
connectivity.freqRng   = freqRng;
connectivity.freqBands = freqBands;
connectivity.label     = dataCut.label;
connectivity.trialinfo = dataCut.trialinfo;

%% save data
if strcmpi(saveData, 'yes')

    outputFilename = [subjectdata.subjectName '_' outputName '.mat'];
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = [subjectdata.PATHS.NETMETDIR filesep ...
        outputFilename];

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
    end

else
    save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
end

%%%%%% extra functions %%%%%%
function connectivity = addRemovedChannels(connectivity, trueRmChannels)

connectivity.label = cat(1,connectivity.label, trueRmChannels);

fnames = fieldnames(connectivity);
fname2use = fnames{not(cellfun(@isempty, strfind(fnames, 'spctrm')))};

currSpctrm = connectivity.(fname2use);
startRow = (size(currSpctrm,1) + 1);
endRow = (size(currSpctrm,1)) + length(trueRmChannels);
currSpctrm(1:size(currSpctrm,1), startRow:endRow, :) = NaN;
currSpctrm(startRow:endRow, 1:size(currSpctrm,2), :) = NaN;

cfg = [];
cfg.channel  = connectivity.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipcomnt   = 'yes';
cfg.skipscale   = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

[~, indxSort] = ismember(lay.label, connectivity.label);
indxSort = indxSort(any(indxSort,2));

currSpctrm = currSpctrm(indxSort, indxSort,:,:);
connectivity.label = connectivity.label(indxSort);
connectivity.(fname2use) = currSpctrm;
