function bv_collectNetmetSummary(cfg)
% Collects a per-subject network-metric table into a cross-subject summary.
%
% Loops over all non-removed subjects, loads each subject's metric file (as
% stored in subjectdata.PATHS), concatenates the per-subject ``.table``
% fields, and writes the result to PATHS.SUMMARY as CSV, MAT, or both.
% Works for any metric whose per-subject output struct has a ``.table``
% field (e.g. the STRENGTH output of bv_calculateStrength).
%
% Args:
%     cfg.inputName (str): Field in ``subjectdata.PATHS`` for the per-subject
%         metric file (e.g. ``'STRENGTH'``). Required.
%     cfg.outputName (str, optional): Base filename (no extension) written to
%         PATHS.SUMMARY. Defaults to ``[lower(inputName) '_summary']``.
%     cfg.format (str, optional): ``'csv'``, ``'mat'``, or ``'both'``
%         (default ``'both'``).
%     cfg.pathsFcn (str, optional): Paths function (default ``'setPaths'``).
%     cfg.quiet (str, optional): ``'yes'``/``'no'`` (default ``'no'``).
%
% Example:
%     ```matlab
%     cfg.inputName  = 'STRENGTH';
%     cfg.outputName = 'strength_summary';
%     cfg.format     = 'both';
%     bv_collectNetmetSummary(cfg);
%     ```

%% get options
inputName  = ft_getopt(cfg, 'inputName');
outputName = ft_getopt(cfg, 'outputName', [lower(inputName) '_summary']);
format     = ft_getopt(cfg, 'format', 'both');
pathsFcn   = ft_getopt(cfg, 'pathsFcn', 'setPaths');
quiet      = ft_getopt(cfg, 'quiet', 'no');

quiet  = strcmpi(quiet, 'yes');
format = lower(format);

if isempty(inputName)
    error('bv_collectNetmetSummary: cfg.inputName is required')
end
if ~ismember(format, {'csv', 'mat', 'both'})
    error('bv_collectNetmetSummary: cfg.format must be ''csv'', ''mat'', or ''both''')
end

writeCsv = ismember(format, {'csv', 'both'});
writeMat = ismember(format, {'mat', 'both'});

eval(pathsFcn)

[~, ~, subjectFolderNames] = bv_getSubjectRange(1, 'end');

allTables = {};

for iSubject = 1:length(subjectFolderNames)
    currSubject       = subjectFolderNames{iSubject};
    subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);

    if ~quiet; fprintf('\t loading %s ... ', currSubject); end

    [~, check, metric] = bv_check4data(subjectFolderPath, inputName);

    if ~check || isempty(metric)
        if ~quiet; fprintf('skipped (%s not found) \n', upper(inputName)); end
        continue
    end

    if ~quiet; fprintf('done \n'); end

    if isfield(metric, 'table') && ~isempty(metric.table)
        allTables{end+1} = metric.table; %#ok<AGROW>
    end
end

if isempty(allTables)
    warning('bv_collectNetmetSummary: no %s data found for any subject', upper(inputName))
    return
end

summaryTable = vertcat(allTables{:});

if writeCsv
    csvPath = fullfile(PATHS.SUMMARY, [outputName '.csv']);
    if ~quiet; fprintf('\t writing summary to %s ... ', csvPath); end
    writetable(summaryTable, csvPath);
    if ~quiet; fprintf('done \n'); end
end

if writeMat
    matPath = fullfile(PATHS.SUMMARY, [outputName '.mat']);
    if ~quiet; fprintf('\t writing summary to %s ... ', matPath); end
    save(matPath, 'summaryTable');
    if ~quiet; fprintf('done \n'); end
end
