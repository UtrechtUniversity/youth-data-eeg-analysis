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
% If the subject folder is no longer under ``PATHS.SUBJECTS`` because
% REMOVINGSUBJECTS moved it to ``PATHS.REMOVED``, the Subject.mat there is
% used. This is how the removal of subjects in a parallel loop ends up in
% the summary (REMOVINGSUBJECTS does not touch the shared file on a parallel
% worker, see that function).
%
% Does nothing (quietly) if the subject folder exists in neither place, or
% ``SubjectSummary.mat`` doesn't exist yet. Warns and does nothing if the
% subject folder has no Subject.mat.
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

if ~exist(subjectFolderPath, 'dir')
    subjectFolderPath = fullfile(PATHS.REMOVED, currSubject);
end

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
