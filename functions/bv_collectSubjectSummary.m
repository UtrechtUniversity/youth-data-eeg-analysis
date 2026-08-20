function bv_collectSubjectSummary(cfg)
% bv_collectSubjectSummary flattens SubjectSummary.mat into a per-subject
% CSV, mirroring the bv_collectPowerSummary.m / bv_collectNetmetSummary.m
% pattern used elsewhere in the pipeline - except here the aggregation is
% already done (SubjectSummary.mat is a struct array with one element per
% subject), so this just selects the useful scalar fields and writes them
% out with writetable.
%
% Deliberately excludes subjectdata.cfgs and subjectdata.PATHS: both are
% nested structs that grow different sub-fields per subject depending on
% which pipeline steps that subject reached, so they don't belong in a
% flat CSV. They remain fully available in SubjectSummary.mat and each
% subject's own Subject.mat for anyone who needs the exact per-step
% configuration.
%
% A field missing for a given subject (e.g. they were removed before
% reaching the step that sets it) reads as NaN (numeric fields) or ''
% (text fields) in the output, same convention as the rest of the
% summary.
%
% Args:
%     cfg.outputFile (str, optional): CSV filename written to
%         PATHS.SUMMARY. Defaults to 'SubjectSummary.csv'.
%     cfg.pathsFcn (str, optional): Paths function filename. Defaults to
%         'setPaths'.
%     cfg.quiet (str, optional): Suppress command window output ('yes' or
%         'no'). Defaults to 'no'.
%
% See also BV_UPDATESUBJECTSUMMARY, BV_COLLECTPOWERSUMMARY, BV_COLLECTNETMETSUMMARY

outputFile = ft_getopt(cfg, 'outputFile', 'SubjectSummary.csv');
pathsFcn   = ft_getopt(cfg, 'pathsFcn', 'setPaths');
quiet      = ft_getopt(cfg, 'quiet', 'no');
quiet      = strcmpi(quiet, 'yes');

eval(pathsFcn)

summaryPath = fullfile(PATHS.SUMMARY, 'SubjectSummary.mat');
if ~exist(summaryPath, 'file')
    warning('bv_collectSubjectSummary: %s not found', summaryPath)
    return
end

load(summaryPath, 'subjectdatasummary')

% field name -> default value (its class also decides whether the column
% is written out numeric or as text). Order here is the output column
% order; matches bv_orderSubjectFields's canonical order minus PATHS/cfgs
% (excluded - see function header).
fieldSpec = struct( ...
    'subjectName',          '', ...
    'wave',                 '', ...
    'pseudo',               '', ...
    'preprocDate',          '', ...
    'testDate',             '', ...
    'testTime',             '', ...
    'removed',              NaN, ...
    'removedDuring',        '', ...
    'removedReason',        '', ...
    'nTrialsPreproc',       NaN, ...
    'resampleFs',           NaN, ...
    'nChannels',            NaN, ...
    'flaggedChannels',      '', ...
    'flatChannels',         '', ...
    'noisyChannels',        '', ...
    'interpolatedChannels', '', ...
    'nEpochsArtefact',      NaN, ...
    'nCleanEpochsArtefact', NaN, ...
    'nEpochsPower',         NaN, ...
    'nCleanEpochsPower',    NaN, ...
    'refElec',              '', ...
    'refMethod',            '');

fieldNames = fieldnames(fieldSpec);
nSubjects  = numel(subjectdatasummary);

columns = struct();
for i = 1:numel(fieldNames)
    f          = fieldNames{i};
    isNumericCol = isnumeric(fieldSpec.(f));

    if isNumericCol
        col = nan(nSubjects, 1);
    else
        col = repmat({''}, nSubjects, 1);
    end

    for s = 1:nSubjects
        if isfield(subjectdatasummary(s), f) && ~isempty(subjectdatasummary(s).(f))
            if isNumericCol
                rawVal = double(subjectdatasummary(s).(f));
                if numel(rawVal) == 1
                    col(s) = rawVal;
                end
                % else: leave col(s) at its NaN default - a non-scalar
                % value here would corrupt the column-vector assignment
            else
                col{s} = toDisplayString(subjectdatasummary(s).(f));
            end
        end
    end
    columns.(f) = col;
end

T = struct2table(columns);

outputPath = fullfile(PATHS.SUMMARY, outputFile);
if ~quiet; fprintf('\t writing subject summary to %s ... ', outputPath); end
writetable(T, outputPath);
if ~quiet; fprintf('done \n'); end


% =========================================================================
function s = toDisplayString(raw)
% collapse a cell-array-of-strings field into one semicolon-joined string;
% leave char arrays as-is; stringify anything else.
if iscell(raw)
    s = strjoin(cellfun(@char, raw, 'UniformOutput', false), '; ');
elseif ischar(raw)
    s = raw;
else
    s = mat2str(raw);
end
