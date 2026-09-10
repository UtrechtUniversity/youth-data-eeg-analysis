function bv_updateSubjectSummary(path2subjectsummary, subjectdata)
% bv_updateSubjectSummary merges one subject's Subject.mat data into the
% shared SubjectSummary.mat struct array, keyed on subjectdata.subjectName.
%
% Field reconciliation (both top-level and nested, e.g. subjectdata.cfgs)
% is delegated to bv_reconcileSummaryArray, which keeps subjectdata and
% every existing row consistent in the way MATLAB struct arrays actually
% require (see that function for why top-level and nested fields need
% different handling).

load(path2subjectsummary, 'subjectdatasummary')

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
