function data = bv_cleanData(cfg, data, artefactdef)
% Removes artefact-ridden trials from a FieldTrip data structure.
%
% Trials exceeding any threshold in ``cfg.lims`` are discarded. The number
% of trials before and after, and the sample indices of the clean trials, are
% stored in subjectdata. Which fields are used depends on ``cfg.stage``, so
% the cleaning of the preprocessing stage and that of the power stage do not
% overwrite each other: ``'artefact'`` writes ``nEpochsArtefact``,
% ``nCleanEpochsArtefact`` and ``cleanSampleInfo``; ``'power'`` writes
% ``nEpochsPower``, ``nCleanEpochsPower`` and ``cleanSampleInfoPower``.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no data is
%         provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.artefactData (str): Field name in ``subjectdata.PATHS`` used to
%         load the artefact struct. Required when no data is provided.
%     cfg.saveData (str): Whether to save data and subjectdata to disk
%         (``'yes'`` or ``'no'``). Required when no data is provided.
%     cfg.outputName (str): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.lims (struct): Rejection thresholds for artefact metrics. Each
%         field must match a metric in the artefact struct (``kurtosis``,
%         ``variance``, ``jump``, ``abs``, ``range``, ``flatline``).
%         Required.
%     cfg.stage (str, optional): Pipeline stage this cleaning belongs to,
%         which decides the subjectdata fields the trial counts and clean
%         sample indices are stored in (see above): ``'artefact'`` (the
%         preprocessing stage) or ``'power'`` (the sliding-window epochs of
%         the power stage). Defaults to ``'artefact'``.
%     cfg.calculateDataloss (str, optional): Whether to compute and store
%         the percentage of lost data in subjectdata (``'yes'`` or
%         ``'no'``). Defaults to ``'no'``.
%     cfg.dataLossLabel (str, optional): The name under which to store
%         the percentage of lost data in subjectdata. Defaults to
%         ``'dataLoss'``.
%     cfg.expectedtrials (int, optional): Expected trial count. Required
%         when ``cfg.calculateDataloss`` is ``'yes'``.
%     cfg.pathsFcn (str): Paths function filename. Must resolve to a valid
%         file on the MATLAB path. Required when no data is provided.
%     cfg.saveCleanData (str, optional): When no data is provided, whether
%         an existing output makes this step skip (``'yes'`` or ``'no'``).
%         The step is skipped, returning empty data, if this is ``'yes'``,
%         ``cfg.overwrite`` is ``'no'``, and the output registered in
%         ``subjectdata.PATHS`` under ``cfg.outputName`` exists on disk.
%         Independent of ``cfg.saveData``, which controls whether the
%         result is saved at the end. Treated as ``'no'`` if omitted.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``); see ``cfg.saveCleanData``. Defaults to
%         ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure. If omitted, loaded
%         from disk using ``cfg.currSubject`` and ``cfg.inputName``.
%     artefactdef (struct, optional): Artefact struct from
%         ``bv_createArtefactStruct``. If omitted, loaded from disk using
%         ``cfg.artefactData``.
%
% Returns:
%     data (struct): FieldTrip data with artefact trials removed. Returns
%         empty (``[]``) if output already exists and ``cfg.overwrite`` is
%         ``'no'``, or if no clean trials are left (the subject is then
%         removed, see REMOVINGSUBJECTS).
%
% Example:
%     Load data and artefacts from disk, reject trials, and save:
%
%     ```matlab
%     cfg = [];
%     cfg.currSubject   = 'B12345_99m';
%     cfg.inputName     = 'FILTERED';
%     cfg.artefactData  = 'ARTEFACT';
%     cfg.outputName    = 'CLEANED';
%     cfg.saveData      = 'yes';
%     cfg.lims.kurtosis = 7;
%     cfg.lims.variance = 5;
%     data = bv_cleanData(cfg);
%     ```

lims                = ft_getopt(cfg, 'lims');
pathsFcn            = ft_getopt(cfg, 'pathsFcn');
currSubject         = ft_getopt(cfg, 'currSubject');
inputName           = ft_getopt(cfg, 'inputName');
outputName          = ft_getopt(cfg, 'outputName');
artefactData        = ft_getopt(cfg, 'artefactData');
saveData            = ft_getopt(cfg, 'saveData');
calculateDataloss   = ft_getopt(cfg, 'calculateDataloss', 'no');
dataLossLabel       = ft_getopt(cfg, 'dataLossLabel', 'dataLoss');
expectedtrials      = ft_getopt(cfg, 'expectedtrials');
stage               = ft_getopt(cfg, 'stage', 'artefact');
saveCleanData       = ft_getopt(cfg, 'saveCleanData');
quiet               = ft_getopt(cfg, 'quiet', 'no');
overwrite           = ft_getopt(cfg, 'overwrite', 'no');

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if isempty(lims)
    error('Please give cfg.lims struct as input')
end
if ~any(strcmp(stage, {'artefact', 'power'}))
    error('bv_cleanData: unknown cfg.stage ''%s'' (valid: artefact, power)', num2str(stage))
end

%% load data
saveSubjectData = 'no';
if nargin < 2
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        disp(currSubject);
        [subjectdata, check] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
    end
    if ~check %#ok<NODEF>
        error('%s: Subject.mat not found', currSubject)
    end

    % skip if the output already exists (bv_saveData registers its path in
    % subjectdata.PATHS under the upper-cased output name)
    if strcmpi(overwrite, 'no') && strcmpi(saveCleanData, 'yes') && ...
            isfield(subjectdata.PATHS, upper(outputName)) && ...
            exist(subjectdata.PATHS.(upper(outputName)), 'file')
        if ~quiet
            fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end

    if ~quiet
        [subjectdata, check, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);
    else
        evalc('[subjectdata, check, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);');
    end
    if ~check %#ok<NODEF>
        error('%s: input data not found', currSubject)
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
elseif isfield(cfg, 'currSubject')
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        disp(currSubject);
        [subjectdata, check] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
    end
    if ~check
        error('%s: Subject.mat not found', currSubject)
    end
    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
    saveSubjectData = 'yes';
else
    subjectdata = struct;
    saveData = 'no';
end

%% reject artefact trials
limFields = fieldnames(lims);
for i = 1:length(limFields)
    cField = limFields{i};

    out(:,:,i) = artefactdef.(cField).levels > lims.(cField);

end

% number of artefact-detection windows this subject was evaluated on
% (see ARTFCTPREPROC/ARTFCTRMCHANNELS's cutintrials/triallength options for
% the 'artefact' stage); the number that survived is stored further below
nWindows = size(artefactdef.sampleinfo, 1);

% dataloss calculation
if strcmpi(calculateDataloss, 'yes')
    nBadTrials  = sum(sum(sum(out,3)>0) > 0);
    nGoodTrials = size(out,2) - nBadTrials;
    subjectdata.(dataLossLabel) = (1 - min([nGoodTrials, expectedtrials]) / expectedtrials) * 100;
end

%% select clean trials
goodTrialIndx = find(sum(sum(out,3)>0) == 0);

cfg = [];
cfg.trl = [artefactdef.sampleinfo(goodTrialIndx,:), zeros(length(goodTrialIndx),1)];
if isempty(cfg.trl)
    removingSubjects([],currSubject, 'no clean trials found')
    data = [];
    return
end
evalc('data = ft_redefinetrial(cfg, data);');

if ~isfield(data, 'trialinfo')
    data.trialinfo = ones(length(data.trial),1);
end

cfg = [];
cfg.trl = data.cfg.trl;
cfg.trl(:,4) = data.trialinfo;
bv_showTrialAmount(cfg);

switch stage
    case 'artefact'
        subjectdata.nEpochsArtefact      = nWindows;
        subjectdata.cleanSampleInfo      = artefactdef.sampleinfo(goodTrialIndx,:);
        subjectdata.nCleanEpochsArtefact = length(goodTrialIndx);
    case 'power'
        subjectdata.nEpochsPower         = nWindows;
        subjectdata.cleanSampleInfoPower = artefactdef.sampleinfo(goodTrialIndx,:);
        subjectdata.nCleanEpochsPower    = length(goodTrialIndx);
end

%% save
if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);
    else
        evalc('bv_saveData(subjectdata, data, outputName);');
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);
    else
        evalc('bv_saveData(subjectdata);');
    end
end
