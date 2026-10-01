function subjectresults = bv_createSubjectResults()
% Rebuilds a subject summary table by rescanning every subject folder.
%
% Reads ``Subject.mat`` from every folder under ``PATHS.SUBJECTS``
% (active subjects) and ``PATHS.REMOVED`` (removed subjects), strips
% per-run-only fields (see ``bv_stripSummaryOnlyFields``), reconciles
% field names across subjects (see ``bv_reconcileSummaryArray``, needed
% since different subjects may have reached different pipeline steps),
% and orders fields canonically (see ``bv_orderSubjectFields``). Unlike
% ``SubjectSummary.mat``, this is always rebuilt fresh from disk rather
% than loaded, so it reflects the current state of every subject folder
% even if ``SubjectSummary.mat`` is stale or missing.
%
% Returns:
%     subjectresults (table): One row per subject (active and removed),
%         converted from the reconciled subjectdata struct array via
%         ``struct2table``. A table with no rows or variables
%         (``table()``) if no subject folders exist yet under
%         ``PATHS.SUBJECTS`` or ``PATHS.REMOVED``.
%
% Example:
%     ```matlab
%     subjectresults = bv_createSubjectResults();
%     ```

eval('setPaths')

fprintf('Creating subject results \n')
fprintf('\t Creating subjectsummary ... ')
subjectdirflags = dir(PATHS.SUBJECTS);
subjectdirflags = subjectdirflags([subjectdirflags.isdir] & ~ismember({subjectdirflags.name}, {'.', '..'}));
subjectdirflags = subjectdirflags(~strcmp(fullfile(PATHS.SUBJECTS, {subjectdirflags.name}), PATHS.REMOVED));
subjectrmflags = dir(PATHS.REMOVED);
subjectrmflags = subjectrmflags([subjectrmflags.isdir] & ~ismember({subjectrmflags.name}, {'.', '..'}));

subjectdirflags = [subjectdirflags; subjectrmflags];

if isempty(subjectdirflags)
    fprintf('done! \n')
    subjectresults = table();
    return
end

for i = 1:length(subjectdirflags)
    lng = printPercDone(length(subjectdirflags), i);
    if i ==1
        evalc('subjectdatasummary = bv_check4data([subjectdirflags(1).folder filesep subjectdirflags(1).name]);');
        subjectdatasummary = bv_stripSummaryOnlyFields(subjectdatasummary);
    else
        evalc('subjectdata = bv_check4data([subjectdirflags(i).folder filesep subjectdirflags(i).name]);');
        subjectdata = bv_stripSummaryOnlyFields(subjectdata);

        % reconcile field names (top-level and nested, e.g. cfgs/PATHS -
        % which pick up different sub-fields per subject depending on
        % which pipeline steps that subject reached) so struct2table
        % below doesn't fail as soon as two subjects' fields don't match.
        [subjectdatasummary(1:i-1), subjectdata] = bv_reconcileSummaryArray(subjectdatasummary(1:i-1), subjectdata);

        subjectdatasummary(i) = subjectdata;

    end
    fprintf(repmat('\b', 1, lng))
end
fprintf('done! \n')
subjectdatasummary = bv_orderSubjectFields(subjectdatasummary);
subjectresults = struct2table(subjectdatasummary);
