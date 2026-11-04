function bv_updateSubjectSummary(path2subjectsummary, subjectdata)
% Merges one subject's data into the shared SubjectSummary.mat.
%
% Loads the summary (a struct array with one row per subject), adds
% subjectdata as a new row or replaces the existing row with the same
% ``subjectdata.subjectName``, and saves it again, with the fields in
% canonical order (see BV_ORDERSUBJECTFIELDS).
%
% Field reconciliation (both top-level and nested, e.g. subjectdata.cfgs)
% is delegated to BV_RECONCILESUMMARYARRAY, which keeps subjectdata and
% every existing row consistent in the way MATLAB struct arrays actually
% require (see that function for why top-level and nested fields need
% different handling).
%
% subjectdata should already have been passed through
% BV_STRIPSUMMARYONLYFIELDS, otherwise the summary-only fields end up in
% the summary.
%
% Args:
%     path2subjectsummary (str): Path to SubjectSummary.mat (the ``.mat``
%         extension is optional). The file must exist and contain the
%         variable ``subjectdatasummary``.
%     subjectdata (struct): Subject info, without summary-only fields.
%         Needs ``subjectName``.
%
% Example:
%     ```matlab
%     bv_updateSubjectSummary(fullfile(PATHS.SUMMARY, 'SubjectSummary'), ...
%         bv_stripSummaryOnlyFields(subjectdata));
%     ```

if ~isfield(subjectdata, 'subjectName')
    error('bv_updateSubjectSummary:noSubjectName', ...
        'subjectdata has no subjectName, so its row in the summary cannot be identified')
end

summary = load(path2subjectsummary, 'subjectdatasummary');
if ~isfield(summary, 'subjectdatasummary')
    error('bv_updateSubjectSummary:noSummary', ...
        '%s does not contain a subjectdatasummary variable', path2subjectsummary)
end
subjectdatasummary = summary.subjectdatasummary;

[subjectdatasummary, subjectdata] = bv_reconcileSummaryArray(subjectdatasummary, subjectdata);

subjectIndx = find(ismember({subjectdatasummary.subjectName}, ...
    subjectdata.subjectName));

if isempty(subjectIndx)
    fprintf('\t %s not found in SubjectSummary, appending as a new row ... \n', subjectdata.subjectName)
    subjectdatasummary(end+1) = subjectdata;
else
    subjectdatasummary(subjectIndx) = subjectdata;
end

subjectdatasummary = bv_orderSubjectFields(subjectdatasummary);

fprintf('\t saving SubjectSummary.mat...')
save(path2subjectsummary, 'subjectdatasummary')
fprintf('done \n')
