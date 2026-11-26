function [data, subjectdata] = removeChannels(cfg, data, artefactdef)
% Flags channels with too many artefact-ridden trials, and optionally repairs them.
%
% A trial counts as bad for a channel if any metric in ``cfg.lims`` exceeds
% its limit in ``artefactdef``. A channel is flagged when the percentage of
% bad trials exceeds ``cfg.maxpercbad``. The flagged channels are recorded
% in ``subjectdata`` (``flaggedChannels``, split by metric into
% ``flatChannels`` and ``noisyChannels``, plus ``nChannels``). They are left
% out the next time the data is read in (see PREPROCRESAMPLE with
% ``cfg.removechans``), or interpolated here when ``cfg.repairchans`` is
% ``'yes'``. A subject with more than ``cfg.maxbadchans`` flagged channels
% is removed (see REMOVINGSUBJECTS).
%
% Channels interpolated here are added to ``subjectdata.interpolatedChannels``,
% which keeps the channels interpolated by earlier steps.
%
% Args:
%     cfg.lims (struct): Rejection thresholds for artefact metrics. Each
%         field must match a metric in the artefact struct (``kurtosis``,
%         ``variance``, ``jump``, ``abs``, ``range``, ``flatline``). A
%         selection of these metrics can be used. The struct is required.
%     cfg.expectedtrials (int, optional): Number of trials the bad-trial
%         percentage is relative to. Defaults to the number of trials in
%         ``artefactdef``.
%     cfg.maxpercbad (number, optional): Maximum percentage of bad trials
%         before a channel is flagged. Defaults to ``40``.
%     cfg.maxbadchans (int, optional): Maximum number of flagged channels
%         before the subject is removed. Defaults to ``3``.
%     cfg.repairchans (str, optional): Whether to interpolate the flagged
%         channels (``'yes'`` or ``'no'``), by averaging their neighbouring
%         channels (``ft_channelrepair`` with method ``'average'``, using
%         neighbours from ``ft_prepare_neighbours`` with triangulation on
%         the layout matching the recording, see GETLAYOUTTYPE; this is
%         read from the header of the subject's raw file, else from
%         ``data.hdr``, and defaults to ``biosemi32.lay`` when neither is
%         available). Forced to ``'yes'`` when data and artefactdef are
%         given without ``cfg.currSubject``. Unset means ``'no'``.
%     cfg.currSubject (str): Subject folder name. Required when data and
%         artefactdef are not provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         the data. Required when data and artefactdef are not provided.
%     cfg.artefactData (str): Field name in ``subjectdata.PATHS`` used to
%         load the artefact struct. Required when data and artefactdef are
%         not provided.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.saveData (str, optional): Whether to save the repaired data
%         (``'yes'`` or ``'no'``). The data is only saved when
%         ``cfg.repairchans`` is ``'yes'`` too, since it is unchanged
%         otherwise. ``Subject.mat`` is saved whenever a subject is
%         involved, whatever this is set to. Forced to ``'no'`` when data
%         is provided.
%     cfg.outputName (str): Label for the output file, its
%         ``subjectdata.PATHS`` entry, and this run's config in
%         ``subjectdata.cfgs``. Required when saving data.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Only checked when no data is provided.
%         Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure. If omitted, loaded
%         from disk using ``cfg.currSubject`` and ``cfg.inputName``.
%     artefactdef (struct, optional): Artefact struct from
%         ``createArtefactStruct``. If omitted, loaded from disk using
%         ``cfg.artefactData``.
%
% Returns:
%     data (struct): The data, with the flagged channels interpolated when
%         ``cfg.repairchans`` is ``'yes'``. Empty (``[]``) if the subject
%         was removed for having too many flagged channels, or if the
%         output already exists and ``cfg.overwrite`` is ``'no'``.
%     subjectdata (struct): Updated subject info.
%
% Example:
%     ```matlab
%     cfg                = [];
%     cfg.currSubject    = 'B12345_99m';
%     cfg.inputName      = 'PREPROC';
%     cfg.artefactData   = 'ARTFCTBEFORE';
%     cfg.outputName     = 'PREPROCRMCHANNELS';
%     cfg.saveData       = 'yes';
%     cfg.lims.kurtosis  = 10;
%     cfg.lims.variance  = 2000;
%     removeChannels(cfg);
%     ```

%% get options
lims            = ft_getopt(cfg, 'lims');
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject     = ft_getopt(cfg, 'currSubject');
inputName       = ft_getopt(cfg, 'inputName');
outputName      = ft_getopt(cfg, 'outputName');
artefactData    = ft_getopt(cfg, 'artefactData');
saveToDisk        = ft_getopt(cfg, 'saveData');
maxpercbad      = ft_getopt(cfg, 'maxpercbad', 40);
expectedtrials  = ft_getopt(cfg, 'expectedtrials');
repairchans     = ft_getopt(cfg, 'repairchans');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');
quiet           = ft_getopt(cfg, 'quiet', 'no');
maxbadchans     = ft_getopt(cfg, 'maxbadchans', 3);

quiet = strcmpi(quiet, 'yes');

if isempty(lims)
    error('Please give cfg.lims struct as input')
end
if strcmpi(saveToDisk, 'yes') && isempty(outputName)
    error('cfg.outputName is required when cfg.saveData is ''yes''')
end

%% load data (if necessary)
hasSubject = true;
if nargin < 2 % data loading
    eval(pathsFcn)

    if ~quiet; disp(currSubject); end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        [subjectdata, check] = check4Data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = check4Data(subjectFolderPath);');
    end
    if ~check %#ok<NODEF>
        error('%s: Subject.mat not found', currSubject)
    end

    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName)); end
                data = [];
                return
            end
        end
    end

    if ~quiet
        [subjectdata, check, data, artefactdef] = check4Data(subjectFolderPath, inputName, artefactData);
    else
        evalc('[subjectdata, check, data, artefactdef] = check4Data(subjectFolderPath, inputName, artefactData);');
    end
    if ~check %#ok<NODEF>
        error('%s: input data not found', currSubject)
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
elseif isfield(cfg, 'currSubject')
    eval(pathsFcn)

    if ~quiet; disp(currSubject); end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        [subjectdata, check] = check4Data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = check4Data(subjectFolderPath);');
    end
    if ~check %#ok<NODEF>
        error('%s: Subject.mat not found', currSubject)
    end
    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
    saveToDisk = 'no';
else
    subjectdata = struct;
    hasSubject = false;
    repairchans = 'yes';
    saveToDisk = 'no';
end

if isempty(expectedtrials)
    expectedtrials = size(artefactdef.sampleinfo,1);
end

%% flag bad channels
if ~quiet; fprintf('\t checking for channels to remove ... \n'); end

% a trial is bad for a channel if any metric exceeds its limit
limFields = fieldnames(lims);
missingMetrics = limFields(~isfield(artefactdef, limFields));
if ~isempty(missingMetrics)
    error('cfg.lims has fields that are not in the artefact struct: %s', ...
        strjoin(missingMetrics, ', '))
end
for i = 1:length(limFields)
    cField = limFields{i};

    out(:,:,i) = artefactdef.(cField).levels > lims.(cField);

end

% badchannel calculation
badchans = data.label(((sum(sum(out,3)>0,2) / expectedtrials) * 100 ) > maxpercbad);
subjectdata.flaggedChannels = badchans;
subjectdata.flatChannels = ...
    data.label(((sum(sum(out(:,:, ...
    contains(limFields, 'flat')),3)>0,2) / expectedtrials) * 100 ) > ...
    maxpercbad);
subjectdata.noisyChannels = ...
    data.label(((sum(sum(out(:,:, ...
    not(contains(limFields, 'flat'))),3)>0,2) / expectedtrials) * 100 ) > ...
    maxpercbad);
subjectdata.nChannels = length(data.label);

% channels interpolated by earlier steps stay on record
if ~isfield(subjectdata, 'interpolatedChannels')
    subjectdata.interpolatedChannels = cell(0);
end

%% remove the subject if too many channels are bad
if length(subjectdata.flaggedChannels) > maxbadchans
    if ~hasSubject
        warning('%d channels flagged, more than cfg.maxbadchans (%d): returning empty data', ...
            length(subjectdata.flaggedChannels), maxbadchans)
        data = [];
        return
    end

    % removingSubjects reloads subjectdata fresh from Subject.mat, so the
    % channel-list fields just set above (flaggedChannels/flatChannels/
    % noisyChannels/nChannels) need to be on disk first, or they're lost -
    % this subject never reaches the saveData call at the bottom of
    % this function otherwise.
    if ~quiet
        saveData(subjectdata);
    else
        evalc('saveData(subjectdata);');
    end
    rmCfg = [];
    rmCfg.pathsFcn = pathsFcn;
    removingSubjects(rmCfg, currSubject, 'too many noisy channels')
    data = [];
    return
end

%% repair the flagged channels (if asked for)
if not(isempty(subjectdata.flaggedChannels))
    if ~quiet; fprintf(['\t \t bad channels detected: ' repmat('%s,', 1, length(badchans)) '\n'], badchans{:}); end

    % badchannel interpolation
    if strcmpi(repairchans, 'yes')
        if ~quiet; fprintf('\t repairing ... '); end
        cfg = [];
        cfg.method          = 'triangulation';
        cfg.layout          = getRepairLayout(data, subjectdata);
        cfg.feedback        = 'no';
        evalc('neighbours = ft_prepare_neighbours(cfg, data);');

        % the flagged channels are still part of data, so they are bad
        % channels, not missing ones (ft_channelrepair errors on missing
        % channels that are present in the data). 'average' only needs the
        % neighbours
        cfg = [];
        cfg.badchannel = subjectdata.flaggedChannels';
        cfg.method = 'average';
        cfg.neighbours = neighbours;
        evalc('data = ft_channelrepair(cfg, data);');

        % keep a record of ALL channels interpolated so far (also by other
        % steps, e.g. preprocResample), not just those of this call
        interpolatedBefore = {};
        if ~isempty(subjectdata.interpolatedChannels)
            interpolatedBefore = cellstr(subjectdata.interpolatedChannels);
        end
        subjectdata.interpolatedChannels = unique( ...
            [interpolatedBefore(:); subjectdata.flaggedChannels(:)], 'stable');
        if ~quiet; fprintf('done! \n'); end
    else
        if ~quiet; fprintf('\t added to subjectdata struct \n'); end
    end
end

%% save data
% Subject.mat is saved whenever a subject is involved; the data only when
% it was repaired (it is unchanged otherwise)
if strcmpi(saveToDisk, 'yes') && strcmpi(repairchans, 'yes')
    if ~quiet
        saveData(subjectdata, data, outputName); % save both data and subjectdata to the drive
    else
        evalc('saveData(subjectdata, data, outputName);'); % save both data and subjectdata to the drive
    end
elseif hasSubject
    if ~quiet
        saveData(subjectdata);
    else
        evalc('saveData(subjectdata);');
    end
end

end


function layout = getRepairLayout(data, subjectdata)
% Layout for the neighbours of the channel repair: determined from the
% header of the subject's raw file, else of the data, via GETLAYOUTTYPE.
% Defaults to biosemi32.lay when no header is available.
layout = 'biosemi32.lay';

hdr = [];
if isfield(subjectdata, 'PATHS') && isfield(subjectdata.PATHS, 'HDRFILES') && ...
        ~isempty(subjectdata.PATHS.HDRFILES) && exist(subjectdata.PATHS.HDRFILES{1}, 'file')
    % the parts of a session have the same channels, so the first one will do
    evalc('hdr = ft_read_header(subjectdata.PATHS.HDRFILES{1});');
elseif isfield(data, 'hdr')
    hdr = data.hdr;
end

if ~isempty(hdr)
    layout = getLayoutType(hdr);
end
end
