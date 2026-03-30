function bv_updateSubjectFile

eval('setPaths')

sDirs = dir(PATHS.SUBJECTS);
sDirs = sDirs([sDirs.isdir] & ~ismember({sDirs.name}, {'.', '..'}));
sDirs = sDirs(~strcmp(fullfile(PATHS.SUBJECTS, {sDirs.name}), PATHS.REMOVED));
sNames = {sDirs.name};

for iSubjects = 1:length(sDirs)
    cSubject = sNames{iSubjects};
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    subjectdata = bv_check4data(subjectFolderPath);
    
    
