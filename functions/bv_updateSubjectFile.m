function bv_updateSubjectFile

eval('setPaths')
eval('setOptions')

sDirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
sNames = {sDirs.name};

for iSubjects = 1:length(sDirs)
    cSubject = sNames{iSubjects};
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    subjectdata = bv_check4data(subjectFolderPath);
    
    
