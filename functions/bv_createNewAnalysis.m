function bv_createNewAnalysis(str, overwrite)
% Creates the folder structure and script templates for a new analysis in
% the EEG connectivity pipeline, inside the current working directory.
%
% Creates ``RAW`` and ``Analyses`` in the current working directory, and a
% dated ``Analyses/<date>[_label]`` analysis folder containing ``config``,
% ``Subjects`` (with a ``removed`` subfolder), and ``summary``
% subfolders, plus ``log.txt``, ``setPaths.m``, ``setOptions.m``,
% ``preprocessingData.m``, ``setOptionsPower.m``, ``powerEstimates.m``,
% ``setOptionsNetmet.m``, and ``networkMetrics.m``. If
% ``preprocessingData.m`` needs to be (re)created, interactively prompts
% (via ``questdlg``) for whether to use parallel processing and whether
% to save intermediate steps, then copies the matching
% ``preprocessingData_standard*`` template. Ends by changing the current
% directory to the new analysis folder.
%
% Args:
%     str (str): Label appended to today's date (``yyyymmdd``) to form
%         the analysis folder name, e.g. ``'test1'`` gives
%         ``'20260929_test1'``. Pass ``''`` or ``""`` to use the date
%         alone.
%     overwrite (bool, optional): Whether to recreate each script and
%         ``log.txt`` if today's analysis folder (and those files)
%         already exist. Defaults to ``false``.
%
% Example:
%     ```matlab
%     bv_createNewAnalysis('test1')
%     ```

if nargin < 2
    overwrite = 0;
end

if ~isempty(str) && str ~= ""
    str = ['_' char(str)];
else
    str = '';
end

PATHS.HOME = pwd;
PATHS.ANALYSES = [PATHS.HOME filesep 'Analyses'];
PATHS.RAW = [PATHS.HOME filesep 'RAW'];

dateFormat = 'yyyymmdd';
currDate = datestr(now, dateFormat);
PATHS.CURRANALYSIS = [PATHS.ANALYSES filesep currDate str];

fprintf('\ncreating folders: \n');
[~, msg] = mkdir(PATHS.ANALYSES);
fprintf('\tanalysis folder: ')
if ~isempty(msg)
    fprintf([msg '\n'])
else
    fprintf('created \n');
end

[~, msg] = mkdir(PATHS.RAW);
fprintf('\traw folder: ')
if ~isempty(msg)
    fprintf([msg '\n'])
else
    fprintf('created \n');
end

[~, msg] = mkdir(PATHS.CURRANALYSIS);
fprintf('\tcurranalysis folder: ')
if ~isempty(msg)
    fprintf([msg '\n'])
else
    fprintf('created \n');
end

fprintf('creating scripts: \n')
fprintf('\t')
if ~overwrite && exist([PATHS.CURRANALYSIS filesep 'setPaths.m'], 'file')
    setPathExist = true(1);
    fprintf('setPaths.m already exists, not overwriting \n')
else
    setPathExist = bv_createSetPaths(PATHS.CURRANALYSIS, PATHS.HOME);
    if setPathExist
        fprintf('setPaths.m created \n')
    else
        fprintf('setPaths.m creation failed, please check  \n')
    end
end

setOptionsExist = createScriptFromTemplate(PATHS.CURRANALYSIS, 'setOptions.m', 'setOptions_preproc', overwrite);

fprintf('\t')
if ~overwrite && exist([PATHS.CURRANALYSIS filesep 'preprocessingData.m'], 'file')
    preprocessExist = true(1);
    fprintf('preprocessingData.m already exists, not overwriting \n')
else
    config = '';
    parprocess = questdlg('Will you use parallel processing?', ...
        'Parallel processing', 'Yes', 'No', 'No');
    saveIntermediate = questdlg('Would you like intermediate steps to be saved?', ...
        'Save intermediate steps', 'Yes', 'No', 'Yes');

    if strcmpi(parprocess, 'Yes')
        config = [config, '-parprocess'];
    end

    if strcmpi(saveIntermediate, 'Yes')
        config = [config, '-saveintermediate'];
    end

    switch config
        case '-parprocess-saveintermediate'
            template = 'preprocessingData_standard_parfor';
        case '-parprocess'
            template = 'preprocessingData_standard_withoutSave_parfor';
        case '-saveintermediate'
            template = 'preprocessingData_standard';
        case ''
            template = 'preprocessingData_standard_withoutSave';
        otherwise
            error('unknown configuration')
    end

    preprocessExist = copyTemplate(PATHS.CURRANALYSIS, 'preprocessingData.m', template);
end

setPowerOptionsExist  = createScriptFromTemplate(PATHS.CURRANALYSIS, 'setOptionsPower.m', 'setOptions_power', overwrite);
powerEstimatesExist   = createScriptFromTemplate(PATHS.CURRANALYSIS, 'powerEstimates.m', 'powerEstimates_standard', overwrite);
setNetmetOptionsExist = createScriptFromTemplate(PATHS.CURRANALYSIS, 'setOptionsNetmet.m', 'setOptions_netmet', overwrite);
networkMetricsExist   = createScriptFromTemplate(PATHS.CURRANALYSIS, 'networkMetrics.m', 'networkMetrics_standard', overwrite);

fprintf('create log: \n')
if ~overwrite && exist([PATHS.CURRANALYSIS filesep 'log.txt'], 'file')
    logExist = true(1);
    fprintf('log.txt already exists, not overwriting \n')
else
    logExist = true(1);
    bv_createNewLog([PATHS.CURRANALYSIS filesep 'log.txt'])
end

fprintf('\n')
if setPathExist && setOptionsExist && preprocessExist && logExist && setPowerOptionsExist && powerEstimatesExist && setNetmetOptionsExist && networkMetricsExist
    fprintf('function finished with no problems !\n')
else
    warning('Function finished with (several) warnings, please check')
end

cd(PATHS.CURRANALYSIS)

end

function ok = createScriptFromTemplate(analysisFolder, targetName, templateName, overwrite)
% Copies templateName (resolved via ``which``) into analysisFolder as
% targetName and reports the outcome, unless targetName already exists
% and overwrite is false.
fprintf('\t')
if ~overwrite && exist([analysisFolder filesep targetName], 'file')
    ok = true(1);
    fprintf('%s already exists, not overwriting \n', targetName)
else
    ok = copyTemplate(analysisFolder, targetName, templateName);
end
end

function ok = copyTemplate(analysisFolder, targetName, templateName)
% Copies templateName (resolved via ``which``) into analysisFolder as
% targetName and reports the outcome.
[ok, msg] = copyfile(which(templateName), [analysisFolder filesep targetName]);
if ok
    fprintf('%s created \n', targetName)
else
    fprintf('%s not created with following warning: \n\t\t %s\n', targetName, msg)
end
end
