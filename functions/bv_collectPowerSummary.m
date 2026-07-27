function bv_collectPowerSummary(cfg)
% Collects per-subject POWER structs and writes a cross-subject summary CSV.
%
% Loops over all non-removed subjects, loads each subject's POWER file
% (as stored in subjectdata.PATHS), concatenates the per-subject tables,
% and writes the result to a CSV file in PATHS.SUMMARY.
%
% Args:
%     cfg.inputName (str, optional): Field name in ``subjectdata.PATHS``
%         for the per-subject power file. Defaults to ``'POWER'``.
%     cfg.outputFile (str, optional): CSV filename written to PATHS.SUMMARY.
%         Defaults to ``'power_summary.csv'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Defaults to
%         ``'setPaths'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%
% Example:
%     ```matlab
%     cfg.inputName  = 'POWER';
%     cfg.outputFile = 'power_summary.csv';
%     bv_collectPowerSummary(cfg);
%     ```

%% get options
inputName  = ft_getopt(cfg, 'inputName', 'POWER');
outputFile = ft_getopt(cfg, 'outputFile', 'power_summary.csv');
pathsFcn   = ft_getopt(cfg, 'pathsFcn', 'setPaths');
quiet      = ft_getopt(cfg, 'quiet', 'no');

quiet = strcmpi(quiet, 'yes');

eval(pathsFcn)

[~, ~, subjectFolderNames] = bv_getSubjectRange(1, 'end');

allTables  = {};
calcMethods = {};

for iSubject = 1:length(subjectFolderNames)
    currSubject       = subjectFolderNames{iSubject};
    subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);

    if ~quiet; fprintf('\t loading %s ... ', currSubject); end

    [~, check, power] = bv_check4data(subjectFolderPath, inputName);

    if ~check || isempty(power)
        if ~quiet; fprintf('⚠ skipped (POWER not found) \n'); end
        continue
    end

    if ~quiet; fprintf('done \n'); end

    if isfield(power, 'table') && ~isempty(power.table)
        allTables{end+1} = power.table; %#ok<AGROW>
    end

    if isfield(power, 'calcMethod')
        calcMethods{end+1} = power.calcMethod; %#ok<AGROW>
    end
end

if isempty(allTables)
    warning('bv_collectPowerSummary: no POWER data found for any subject')
    return
end

if numel(unique(calcMethods)) > 1
    warning('bv_collectPowerSummary: subjects were processed with different calcMethod values (%s); summary mixes these', strjoin(unique(calcMethods), ', '))
end

T = vertcat(allTables{:});

outputPath = fullfile(PATHS.SUMMARY, outputFile);
if ~quiet; fprintf('\t writing summary to %s ... ', outputPath); end
writetable(T, outputPath);
if ~quiet; fprintf('done \n'); end
