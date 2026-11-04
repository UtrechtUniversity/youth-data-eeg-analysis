function bv_syncSubjectSummary(currSubject, pathsFcn)
% Merges a subject's Subject.mat into the shared SubjectSummary.mat.
%
% Reloads currSubject's Subject.mat from disk and merges it into
% SubjectSummary.mat, so that every pipeline step's cfg (and any other
% field it wrote onto subjectdata) ends up in the shared summary, not just
% in that subject's own file. Fields listed in BV_STRIPSUMMARYONLYFIELDS
% are left out of the summary.
%
% Intended to be called once per subject at the end of each per-subject
% loop iteration in preprocessingData_*.m, powerEstimates_*.m
% and networkMetrics_*.m, after whatever step just ran.
%
% Does nothing (quietly) if:
%   - the subject folder no longer exists under ``PATHS.SUBJECTS``: it was
%     already moved to ``PATHS.REMOVED`` by REMOVINGSUBJECTS, which updates
%     the summary itself before moving the folder, or
%   - ``SubjectSummary.mat`` doesn't exist yet.
% Warns and does nothing if the subject folder has no Subject.mat.
%
% Args:
%     currSubject (str): Subject folder name.
%     pathsFcn (str, optional): Paths function filename. Must resolve to a
%         valid file on the MATLAB path. Defaults to ``'setPaths'``.
%
% Example:
%     ```matlab
%     bv_syncSubjectSummary('B12345_99m');
%     ```

if nargin < 2 || isempty(pathsFcn)
    pathsFcn = 'setPaths';
end

eval(pathsFcn)

subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);
summaryPath       = fullfile(PATHS.SUMMARY, 'SubjectSummary.mat');

if ~exist(subjectFolderPath, 'dir') || ~exist(summaryPath, 'file')
    return
end

evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
if ~check %#ok<NODEF>
    warning('bv_syncSubjectSummary:noSubjectMat', ...
        '%s: Subject.mat not found, summary not updated', currSubject)
    return
end

subjectdata = bv_stripSummaryOnlyFields(subjectdata);
bv_updateSubjectSummary(fullfile(PATHS.SUMMARY, 'SubjectSummary'), subjectdata);
