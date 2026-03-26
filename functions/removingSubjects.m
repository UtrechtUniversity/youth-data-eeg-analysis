function removingSubjects(cfg, currSubject, reason)

fprintf('\t %s: removing for the following reason: %s ... \n', currSubject, reason)

cfg.optionsFcn = ft_getopt(cfg, 'optionsFcn', 'setOptions');
cfg.pathsFcn = ft_getopt(cfg, 'pathsFcn', 'setPaths');

eval(cfg.optionsFcn)
eval(cfg.pathsFcn)

subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
evalc('subjectdata = bv_check4data(subjectFolderPath);');

lastCalled = dbstack('-completenames',1);

subjectdata.removed = true(1);
if isempty(lastCalled)
    subjectdata.removedDuring = 'commandline';
else
    subjectdata.removedDuring = lastCalled(1).name;
end
subjectdata.removedreason = reason;

evalc('bv_saveData(subjectdata);');

if exist([PATHS.SUMMARY filesep 'SubjectSummary'], 'file')
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
end
subjectdata.PATHS.SUBJECTDIR = [PATHS.REMOVED filesep currSubject];

movefile([PATHS.SUBJECTS filesep currSubject], PATHS.REMOVED)
fprintf('done! \n')
end