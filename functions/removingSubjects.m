function removingSubjects(cfg, currSubject, reason)
% Marks a subject as removed and moves its folder to the removed directory.
%
% Called by the pipeline functions when a subject cannot (or should not) be
% processed further, e.g. no trials found, too many noisy channels or an
% error in a pipeline step. The subject's Subject.mat is loaded fresh from
% disk and flagged with ``removed``, ``removedDuring`` (name of the caller
% function, or ``'commandline'``) and ``removedReason``. The subject folder
% is then moved from ``PATHS.SUBJECTS`` to ``PATHS.REMOVED``,
% ``subjectdata.PATHS.SUBJECTDIR`` is updated to the new location, and
% Subject.mat is saved there. If SubjectSummary.mat exists, the subject's
% row in it is updated too.
%
% If a folder with the same name already exists in ``PATHS.REMOVED`` (the
% subject was removed in an earlier run), a warning is issued and nothing
% is changed.
%
% Because Subject.mat is reloaded from disk, anything the caller changed in
% its in-memory ``subjectdata`` must be saved (bv_saveData) before calling
% this function, or it is lost.
%
% Args:
%     cfg (struct or []): Options. May be empty.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve to
%         a script that defines ``PATHS`` with at least ``SUBJECTS``,
%         ``REMOVED`` and ``SUMMARY``. Defaults to ``'setPaths'``.
%     currSubject (str): Subject folder name (inside ``PATHS.SUBJECTS``).
%     reason (str): Why the subject is removed. Printed and stored in
%         ``subjectdata.removedReason``.
%
% Example:
%     ```matlab
%     removingSubjects([], currSubject, 'no clean trials found')
%     ```

fprintf('\t %s: removing for the following reason: %s ... \n', currSubject, reason)

pathsFcn = ft_getopt(cfg, 'pathsFcn', 'setPaths');

eval(pathsFcn)

subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
if ~check %#ok<NODEF>
    error('removingSubjects:noSubject', ...
        '%s: cannot remove subject, Subject.mat not found in %s', currSubject, subjectFolderPath)
end

removedFolderPath = [PATHS.REMOVED filesep currSubject];
if exist(removedFolderPath, 'dir')
    warning('removingSubjects:alreadyRemoved', ...
        ['%s: not removing subject, %s already exists (the subject was removed in an ' ...
        'earlier run) - move or delete that folder to remove it again'], currSubject, removedFolderPath)
    return
end

lastCalled = dbstack('-completenames',1);

subjectdata.removed = true(1);
if isempty(lastCalled)
    subjectdata.removedDuring = 'commandline';
else
    subjectdata.removedDuring = lastCalled(1).name;
end
subjectdata.removedReason = reason;

% flag the subject in place first, so it is marked even if the move fails
evalc('bv_saveData(subjectdata);');

movefile(subjectFolderPath, PATHS.REMOVED)

% point the subject at its new location and save Subject.mat there
subjectdata.PATHS.SUBJECTDIR = removedFolderPath;
evalc('bv_saveData(subjectdata);');

if exist([PATHS.SUMMARY filesep 'SubjectSummary.mat'], 'file')
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], bv_stripSummaryOnlyFields(subjectdata))
end
fprintf('done! \n')
end
