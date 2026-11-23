function bv_createNewAnalysis(str, overwrite)
% Creates the folder structure and script templates for a new analysis in
% the EEG connectivity pipeline, inside the current working directory.
%
% Creates ``RAW`` and ``Analyses`` in the current working directory, and a
% dated ``Analyses/<date>[_label]`` analysis folder containing ``config``,
% ``Subjects`` (with a ``removed`` subfolder), and ``summary``
% subfolders, plus ``log.txt``, ``setPaths.m``, ``setOptions.m``,
% ``preprocessingData.m``, ``setOptionsPower.m``, ``powerEstimates.m``,
% ``setOptionsNetmet.m``, and ``networkMetrics.m``.
%
% ``preprocessingData.m``, ``powerEstimates.m`` and ``networkMetrics.m``
% come in four variants (``preprocessingData_standard*``,
% ``powerEstimates_standard*`` and ``networkMetrics_standard*``, with the
% suffixes ``_parfor``, ``_withoutSave`` or ``_withoutSave_parfor``).
% The function always prompts (via ``questdlg``) for whether to use
% parallel processing and whether to save intermediate steps, and the
% answers apply to all three scripts. A script that does not exist yet is
% created. A script that already exists is kept if it is the variant picked,
% and replaced by the picked variant if it is another one (including any
% edits made to it, even if ``overwrite`` is ``false``). The variant of an
% existing script is recognised from its contents (a ``parfor`` loop, and
% the 'WITHOUT SAVING INTERMEDIATE STEPS' title). If a dialog is closed
% without answering, existing scripts are left as they are, and new ones
% get the default (no parallel processing, save intermediate steps). Ends by
% changing the current directory to the new analysis folder.
%
% Args:
%     str (str): Label appended to today's date (``yyyymmdd``) to form
%         the analysis folder name, e.g. ``'test1'`` gives
%         ``'20260929_test1'``. Pass ``''`` or ``""`` to use the date
%         alone.
%     overwrite (bool, optional): Whether to recreate each script and
%         ``log.txt`` if today's analysis folder (and those files)
%         already exist, regardless of the variant picked. Defaults to
%         ``false``.
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

% preprocessingData.m, powerEstimates.m and networkMetrics.m come in the same
% four variants (see askVariantSuffix), chosen once for all three
[variantSuffix, cancelled] = askVariantSuffix();

preprocessExist = placeVariantScript(PATHS.CURRANALYSIS, 'preprocessingData.m', ...
    'preprocessingData_standard', variantSuffix, cancelled, overwrite);

setPowerOptionsExist  = createScriptFromTemplate(PATHS.CURRANALYSIS, 'setOptionsPower.m', 'setOptions_power', overwrite);
powerEstimatesExist   = placeVariantScript(PATHS.CURRANALYSIS, 'powerEstimates.m', ...
    'powerEstimates_standard', variantSuffix, cancelled, overwrite);
setNetmetOptionsExist = createScriptFromTemplate(PATHS.CURRANALYSIS, 'setOptionsNetmet.m', 'setOptions_netmet', overwrite);
networkMetricsExist   = placeVariantScript(PATHS.CURRANALYSIS, 'networkMetrics.m', ...
    'networkMetrics_standard', variantSuffix, cancelled, overwrite);

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

function [suffix, cancelled] = askVariantSuffix()
% Asks whether to use parallel processing and whether to save intermediate
% steps, and returns the template name suffix for that choice: ``''``
% (serial, saves intermediate steps), ``'_parfor'``, ``'_withoutSave'`` or
% ``'_withoutSave_parfor'``. ``cancelled`` is true if a dialog was closed
% without answering; the suffix is then that of the default buttons (no
% parallel processing, save intermediate steps).
parprocess = questdlg('Will you use parallel processing?', ...
    'Parallel processing', 'Yes', 'No', 'No');
saveIntermediate = questdlg('Would you like intermediate steps to be saved?', ...
    'Save intermediate steps', 'Yes', 'No', 'Yes');

cancelled = isempty(parprocess) || isempty(saveIntermediate);

suffix = '';
if strcmpi(saveIntermediate, 'No')
    suffix = [suffix '_withoutSave'];
end
if strcmpi(parprocess, 'Yes')
    suffix = [suffix '_parfor'];
end
end

function ok = placeVariantScript(analysisFolder, targetName, templateBase, suffix, cancelled, overwrite)
% Puts the variant ``[templateBase suffix]`` in analysisFolder as
% targetName: creates it if missing, keeps an existing script of the same
% variant (or any existing script when the prompt was cancelled), and
% replaces an existing script of another variant.
target = [analysisFolder filesep targetName];
fprintf('\t')
if ~overwrite && exist(target, 'file')
    if cancelled || strcmp(detectVariantSuffix(target), suffix)
        ok = true(1);
        fprintf('%s already exists, not overwriting \n', targetName)
        return
    end
    fprintf('%s exists with other variant, replacing it ... ', targetName)
end
ok = copyTemplate(analysisFolder, targetName, [templateBase suffix]);
end

function suffix = detectVariantSuffix(scriptPath)
% Recognises the variant of a preprocessingData/powerEstimates/networkMetrics script from
% its contents: a parfor loop makes it parallel, the title of the
% withoutSave templates makes it a script without intermediate steps.
txt = fileread(scriptPath);
suffix = '';
if ~isempty(regexp(txt, '^%% [^\n]*WITHOUT SAVING INTERMEDIATE STEPS', 'once', 'lineanchors'))
    suffix = [suffix '_withoutSave'];
end
if ~isempty(regexp(txt, '^\s*parfor\s*\(', 'once', 'lineanchors'))
    suffix = [suffix '_parfor'];
end
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
