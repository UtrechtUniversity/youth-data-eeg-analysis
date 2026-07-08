function data = bv_appendfieldtripdata(cfg, dataOld)
% Appends trials in a FieldTrip data structure based on sampleinfo.
%
% Output is suitable for use with bv_cutAppendedIntoTrials to segment
% into trials of a desired length.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no data
%         is provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.saveData (str): Whether to save output to disk (``'yes'`` or
%         ``'no'``). Required when no data is provided.
%     cfg.outputName (str): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.optionsFcn (str, optional): Options function filename. Must
%         resolve to a valid file on the MATLAB path.
%         Defaults to ``'setOptions'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
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
% Note:
%     When dataOld is provided, ``cfg.saveData`` is ignored and the result
%     is never saved to disk.
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
%     With pre-loaded data:
%
%     ```matlab
%     cfg = struct();
%     data = bv_appendfieldtripdata(cfg, data);
%     ```

%% get options
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
saveData    = ft_getopt(cfg, 'saveData');
outputName  = ft_getopt(cfg, 'outputName');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

%% load in data (if necessary)
if nargin < 2
    eval(optionsFcn);
    eval(pathsFcn);
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    if strcmpi(overwrite, 'no') & strcmpi(saveData, 'yes') & ...
            exist(fullfile(subjectFolderPath, 'preproc', [currSubject '_' upper(outputName) '.mat']), 'file')
        if ~quiet
            fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end

    if ~quiet
        disp(currSubject)
        [subjectdata, ~, dataOld] = bv_check4data(subjectFolderPath, inputName);
    else
        evalc('[subjectdata, ~, dataOld] = bv_check4data(subjectFolderPath, inputName);');
    end

    subjectdata.cfgs.(outputName) = cfgIn;
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
        bv_saveData(subjectdata, data, outputName); %#ok<NODEF>
    else
        evalc('bv_saveData(subjectdata, data, outputName);');
    end
end