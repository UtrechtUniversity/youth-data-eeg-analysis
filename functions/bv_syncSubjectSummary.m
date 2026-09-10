function bv_syncSubjectSummary(currSubject, pathsFcn)
% bv_syncSubjectSummary reloads currSubject's Subject.mat and merges it
% into SubjectSummary.mat, so that every pipeline step's cfg (and any
% other field it wrote onto subjectdata) ends up in the shared summary,
% not just that subject's own file.
%
% Intended to be called once per subject at the end of each per-subject
% loop iteration in e.g. preprocessingData_standard.m, powerEstimates_standard.m
% and networkMetrics_standard.m, after whatever step just ran.
%
% Does nothing (quietly) if:
%   - currSubject no longer exists under PATHS.SUBJECTS - it was already
%     moved to PATHS.REMOVED by removingSubjects.m, which syncs the
%     summary itself before moving the folder, or
%   - SubjectSummary.mat doesn't exist yet.
%
% Use as
%   bv_syncSubjectSummary(currSubject)
%   bv_syncSubjectSummary(currSubject, pathsFcn)
%
% the following fields are optional
%   pathsFcn    = 'string': filename of m-file to be read with all
%                   necessary paths (default: 'setPaths')
%
% See also BV_UPDATESUBJECTSUMMARY, REMOVINGSUBJECTS

if nargin < 2 || isempty(pathsFcn)
    pathsFcn = 'setPaths';
end

eval(pathsFcn)

subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);
summaryPath       = fullfile(PATHS.SUMMARY, 'SubjectSummary.mat');

if ~exist(subjectFolderPath, 'dir') || ~exist(summaryPath, 'file')
    return
end

evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
subjectdata = bv_stripSummaryOnlyFields(subjectdata);
bv_updateSubjectSummary(fullfile(PATHS.SUMMARY, 'SubjectSummary'), subjectdata);
