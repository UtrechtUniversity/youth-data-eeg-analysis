function data = bv_appendfieldtripdata(cfg, dataOld)
% Appends trials in a FieldTrip data structure based on sampleinfo.
%
% Output is suitable for use with bv_redefineTriallength to cut it into
% epochs of a desired length.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no data
%         is provided. When data is provided as well, it links the result
%         to the subject, so it can be saved (see ``cfg.saveData``).
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.saveData (str, optional): Whether to save the appended data to
%         disk (``'yes'`` or ``'no'``). Subject.mat is saved whenever a
%         subject is involved, whatever this is set to. Without
%         ``cfg.currSubject`` the data is never saved. Defaults to
%         ``'no'``.
%     cfg.outputName (str): Unique label for output file, its
%         ``subjectdata.PATHS`` entry, and this run's config in
%         ``subjectdata.cfgs``. Required when saving data.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Only checked when no data is provided; an
%         existing output then makes the function return empty without
%         doing anything. Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     dataOld (struct, optional): FieldTrip data structure containing
%         multiple trials. If omitted, data is loaded from disk using
%         ``cfg.currSubject`` and ``cfg.inputName``.
%
% Returns:
%     data (struct): FieldTrip data appended according to sampleinfo.
%         Returns empty (``[]``) if output already exists and
%         ``cfg.overwrite`` is ``'no'``.
%
% Example:
%     Load data from disk and save the result:
%
%     ```matlab
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputName   = 'CLEANED';
%     cfg.outputName  = 'APPEND';
%     cfg.saveData    = 'yes';
%     data = bv_appendfieldtripdata(cfg);
%     ```
%
%     With pre-loaded data, still saving the result for the subject:
%
%     ```matlab
%     cfg.currSubject = 'B12345_99m';
%     cfg.outputName  = 'APPEND';
%     cfg.saveData    = 'yes';
%     data = bv_appendfieldtripdata(cfg, data);
%     ```
%
%     With pre-loaded data and no subject (nothing is saved):
%
%     ```matlab
%     data = bv_appendfieldtripdata(struct(), data);
%     ```

%% get options
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
saveData    = ft_getopt(cfg, 'saveData');
outputName  = ft_getopt(cfg, 'outputName');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');

cfgIn = cfg;

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if strcmpi(saveData, 'yes') && isempty(outputName)
    error('bv_appendfieldtripdata: cfg.outputName is required when cfg.saveData is ''yes''')
end

%% load in data (if necessary)
saveSubjectData = 'no';
if nargin < 2
    eval(pathsFcn);

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        disp(currSubject)
        [subjectdata, check] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
    end
    if ~check
        error('%s: Subject.mat not found', currSubject)
    end

    % skip if the output already exists (bv_saveData registers its path in
    % subjectdata.PATHS under the upper-cased output name)
    if strcmpi(overwrite, 'no') && strcmpi(saveData, 'yes') && ...
            isfield(subjectdata.PATHS, upper(outputName)) && ...
            exist(subjectdata.PATHS.(upper(outputName)), 'file')
        if ~quiet
            fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end

    if ~quiet
        [subjectdata, check, dataOld] = bv_check4data(subjectFolderPath, inputName);
    else
        evalc('[subjectdata, check, dataOld] = bv_check4data(subjectFolderPath, inputName);');
    end
    if ~check
        error('%s: input data not found', currSubject)
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfgIn;
    end
elseif ~isempty(currSubject)
    % data handed over for a subject: load its subjectdata, so the result
    % can be saved against it
    eval(pathsFcn);

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        [subjectdata, check] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
    end
    if ~check
        error('%s: Subject.mat not found', currSubject)
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfgIn;
    end
    saveSubjectData = 'yes';
else
    saveData = 'no';
end

%% calculating own trl for appending data
if ~quiet; fprintf('\t appending cleaned data based on data.sampleinfo ... '); end
startTrial = dataOld.sampleinfo(:,1);
endTrial = dataOld.sampleinfo(:,2);
tmptrl(:,1) = startTrial(logical([1; diff(startTrial) ~= length(dataOld.trial{1})]));
tmptrl(:,2) = endTrial(logical([diff(startTrial) ~= length(dataOld.trial{1}); 1]));

if isfield(dataOld, 'trialinfo')
    tmptrialinfo = dataOld.trialinfo(ismember(dataOld.sampleinfo(:,1), tmptrl(:,1)));

    trl = [tmptrl zeros(length(tmptrialinfo),1) tmptrialinfo];
else
    trl = [tmptrl zeros(length(tmptrl),1)];
end

%% redefining trials based on calculated trl
cfg = [];
cfg.trl = trl;
evalc('data = ft_redefinetrial(cfg, dataOld);');
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
