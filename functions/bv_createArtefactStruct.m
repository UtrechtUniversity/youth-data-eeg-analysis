function [artefactdef] = bv_createArtefactStruct(cfg, data)
% Computes per-trial artefact metrics (variance, kurtosis, range, ...) for
% EEG data.
%
% Output is suitable for use with bv_removeChannels or bv_cleanData to
% reject artefact-ridden channels/trials based on thresholds.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no data
%         is provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.pathsFcn (str): Paths function filename. Must resolve to a valid
%         file on the MATLAB path. Required when no data is provided.
%     cfg.saveData (str, optional): Whether to save output to disk
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.outputName (str): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.analyses (str or cell array of str, optional): Artefact metrics
%         to compute, matched case-insensitively by substring (e.g.
%         ``'var'`` matches ``'variance'``). Options: ``'variance'``,
%         ``'kurtosis'``, ``'range'``, ``'flatline'`` (1 / peak-to-peak
%         range), ``'abs'`` (max absolute amplitude), ``'jump'`` (per-
%         channel jump detection via ``ft_artifact_jump``; slow), or
%         ``'all'`` (all of the above). Defaults to ``'all'``.
%     cfg.cutintrials (str, optional): Whether to redefine data into
%         fixed-length trials (via ``ft_redefinetrial``) before computing
%         artefact levels. Requires ``cfg.triallength`` when ``'yes'``.
%         Defaults to ``'no'``.
%     cfg.triallength (int): Trial length in seconds. Required when
%         ``cfg.cutintrials`` is ``'yes'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure containing
%         multiple trials. If omitted, data is loaded from disk using
%         ``cfg.currSubject`` and ``cfg.inputName``.
%
% Returns:
%     artefactdef (struct): One field per computed metric in
%         ``cfg.analyses`` (e.g. ``artefactdef.kurtosis.levels``, a
%         channel x trial matrix), plus ``sampleinfo`` copied from the
%         input data. Returns empty (``[]``) if output already exists and
%         ``cfg.overwrite`` is ``'no'``, or if an error occurs while
%         ``cfg.currSubject`` is set (the subject is skipped via
%         removingSubjects and processing continues).
%
% Example:
%     Compute variance and kurtosis levels and save to disk:
%
%     ```matlab
%     cfg = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputName   = 'CLEANED';
%     cfg.outputName  = 'ARTEFACT';
%     cfg.saveData    = 'yes';
%     cfg.analyses    = {'variance', 'kurtosis'};
%     artefactdef = bv_createArtefactStruct(cfg);
%     ```
%
% See also BV_SAVEDATA BV_CHECK4DATA FT_REDEFINETRIAL FT_ARTIFACT_JUMP

inputName       = ft_getopt(cfg, 'inputName');
outputName      = ft_getopt(cfg, 'outputName');
saveData        = ft_getopt(cfg, 'saveData');
currSubject     = ft_getopt(cfg, 'currSubject');
pathsFcn        = ft_getopt(cfg, 'pathsFcn');
cutintrials     = ft_getopt(cfg, 'cutintrials', 'no');
triallength     = ft_getopt(cfg, 'triallength');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');
quiet           = ft_getopt(cfg, 'quiet', 'no');
analyses        = ft_getopt(cfg, 'analyses', 'all');

cfgIn = cfg;

if strcmpi(analyses, 'all')
    analyses = {'var', 'kurtosis', 'range', 'flatline', 'abs', 'jump'};
end

if ~iscell(analyses)
    analyses = {analyses};
end

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

saveSubjectData = 'no';
if nargin < 2

    if isempty(pathsFcn)
        error('please add options function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end

    if ~quiet; disp(currSubject); end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        [subjectdata] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
    end
    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName)); end
                artefactdef = [];
                return
            end
        end
    end

    if ~quiet
        [~, ~, data] = bv_check4data(subjectFolderPath, inputName);
    else
        evalc('[~, ~, data] = bv_check4data(subjectFolderPath, inputName);');
    end

    subjectdata.cfgs.(outputName) = cfgIn;
else
    if isfield(cfg, 'currSubject')
        if isempty(pathsFcn)
            error('please add options function cfg.pathsFcn')
        else
            eval(pathsFcn)
        end

        if ~quiet; disp(currSubject); end
        subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
        if ~quiet
            [subjectdata] = bv_check4data(subjectFolderPath);
        else
            evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
        end

        saveSubjectData = 'yes';
    end
    saveData = 'no';
    overwrite = 'no';
end

hasSubject = ~isempty(currSubject);

try
    if strcmpi(cutintrials, 'yes')
        cfg = [];
        cfg.length = triallength;
        cfg.overlap = 0;
        evalc('data = ft_redefinetrial(cfg, data);');
    end

    doKurtosis  = contains('kurtosis', analyses, 'IgnoreCase', true);
    doVariance  = contains('variance', analyses, 'IgnoreCase', true);
    doFlatline  = contains('flatline', analyses, 'IgnoreCase', true);
    doRange     = contains('range', analyses, 'IgnoreCase', true);
    doAbs       = contains('abs', analyses, 'IgnoreCase', true);
    doJump      = contains('jump', analyses, 'IgnoreCase', true);

    if ~quiet; fprintf('\t calculating artefact levels ... '); end
    for i = 1:length(data.trial)
        if doKurtosis
            artefactdef.kurtosis.levels(:,i) = kurtosis(data.trial{i}, [], 2);
        end
        if doVariance
            artefactdef.variance.levels(:,i) = std(data.trial{i}, [], 2).^2;
        end
        if doFlatline
            artefactdef.flatline.levels(:,i) = 1./(abs(max(data.trial{i},[],2) - min(data.trial{i},[],2)));
        end
        if doRange
            artefactdef.range.levels(:,i) = max(data.trial{i}, [], 2) - min(data.trial{i}, [], 2);
        end
        if doAbs
            artefactdef.abs.levels(:,i) = max(abs(data.trial{i}), [],2);
        end
    end

    if doJump
        artefactdef.jump.levels = zeros(length(data.label), length(data.trial));
        counter = 0;
        for i = 1:length(data.label)
            cfg = [];
            cfg.artfctdef.jump.channel = data.label{i};
            cfg.continuous = 'no';
            [tmp,artifact] = ft_artifact_jump(cfg, data);
            for j = 1:size(artifact,1)
                counter = counter + 1;
                [~,sel] = min(abs(mean(data.sampleinfo(:,1:2),2) - mean(artifact(j,:))));
                artefactdef.jump.levels(i,sel) = 1;
            end
        end
    end
    if ~quiet; fprintf('done! \n'); end

    artefactdef.sampleinfo = data.sampleinfo;
catch ME
    if hasSubject
        if ~quiet; fprintf('\n \t \t error while calculating artefact levels, removing subject and continuing ... \n'); end
        removingSubjectsCfg = [];
        removingSubjectsCfg.pathsFcn = pathsFcn;
        removingSubjects(removingSubjectsCfg, currSubject, ['artefact calculation - ' ME.message])
        artefactdef = [];
        return
    else
        rethrow(ME)
    end
end

if strcmpi(saveData, 'yes')

    if ~quiet
        bv_saveData(subjectdata, artefactdef, outputName);
    else
        evalc('bv_saveData(subjectdata, artefactdef, outputName);');
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);
    else
        evalc('bv_saveData(subjectdata);');
    end
end
