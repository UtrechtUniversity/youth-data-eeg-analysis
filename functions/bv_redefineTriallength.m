function data = bv_redefineTriallength(cfg, data)
% Cuts existing trials into (optionally overlapping) fixed-length epochs.
%
% Uses FT_REDEFINETRIAL. Each original trial is segmented independently,
% so trialinfo (e.g. condition labels) carries over correctly to every
% resulting epoch, and trials don't need to be adjacent/continuous.
% Trials shorter than ``cfg.triallength`` are dropped by FieldTrip.
%
% Args:
%     cfg.triallength (number): Length of the resulting epochs, in seconds.
%     cfg.overlap (number, optional): Fraction (0-1, exclusive) of overlap
%         between consecutive epochs. Defaults to ``0`` (no overlap). E.g.
%         for 3 s epochs with a 1 s step use ``cfg.triallength = 3`` and
%         ``cfg.overlap = 2/3``.
%     cfg.currSubject (str): Subject folder name. Required when no data is
%         provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.saveData (str, optional): Whether to save the output to disk
%         (``'yes'`` or ``'no'``). Forced to ``'no'`` when data is
%         provided without ``cfg.currSubject``. Defaults to ``'no'``.
%     cfg.outputName (str): Label for the output file and its
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Only checked when no data is provided
%         and ``cfg.saveData`` is ``'yes'``. Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure to cut. If omitted,
%         it is loaded from disk using ``cfg.currSubject`` and
%         ``cfg.inputName``.
%
% Returns:
%     data (struct): FieldTrip data cut into epochs. Empty (``[]``) if the
%         output already exists and ``cfg.overwrite`` is ``'no'``.
%
% Example:
%     ```matlab
%     cfg             = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputName   = 'APPEND';
%     cfg.outputName  = 'EPOCHS';
%     cfg.triallength = 3;
%     cfg.overlap     = 2/3;
%     cfg.saveData    = 'yes';
%     data = bv_redefineTriallength(cfg);
%     ```

%% get options
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
outputName  = ft_getopt(cfg, 'outputName');
saveData    = ft_getopt(cfg, 'saveData', 'no');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');
triallength = ft_getopt(cfg, 'triallength');
overlap     = ft_getopt(cfg, 'overlap', 0);

quiet = strcmpi(quiet, 'yes');

if isempty(triallength)
    error('please specify cfg.triallength')
end
if strcmpi(saveData, 'yes') && isempty(outputName)
    error('cfg.outputName is required when cfg.saveData is ''yes''')
end

%% load data (if necessary)
saveSubjectData = 'no';
if nargin < 2 % data loading
    eval(pathsFcn)

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
    if strcmpi(overwrite, 'no') && strcmpi(saveData, 'yes') && ...
            isfield(subjectdata.PATHS, upper(outputName)) && ...
            exist(subjectdata.PATHS.(upper(outputName)), 'file')
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end

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

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
elseif isfield(cfg, 'currSubject')
    eval(pathsFcn)

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
    saveSubjectData = 'yes';
else
    subjectdata = struct;
    saveData = 'no';
end

%% cut into epochs
% ft_redefinetrial silently drops any trial shorter than cfg.length when
% cutting into fixed-length (sub-)windows. If *every* trial is too short,
% it's left with nothing to redefine and throws a generic, misleading
% "you should specify at least one configuration option" error instead of
% saying so directly - check for that case up front instead.
trialDurations = (data.sampleinfo(:,2) - data.sampleinfo(:,1) + 1) ./ data.fsample;
if max(trialDurations) < triallength
    error('no trials long enough for %ss epoching (longest available trial: %.2fs)', ...
        num2str(triallength), max(trialDurations))
end

if ~quiet; fprintf('\t redefining triallength to %ss (overlap %s) ... ', num2str(triallength), num2str(overlap)); end
ftcfg         = [];
ftcfg.length  = triallength;
ftcfg.overlap = overlap;
evalc('data = ft_redefinetrial(ftcfg, data);');
if ~quiet; fprintf('done! \n'); end

%% save data
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
