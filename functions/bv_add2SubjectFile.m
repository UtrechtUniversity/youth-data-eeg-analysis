function bv_add2SubjectFile(subjectName, varName, value)

eval('setOptions')
eval('setPaths')

subjectFolderPath = [PATHS.SUBJECTS filesep subjectName];
[subjectdata] = bv_check4data(subjectFolderPath);

subjectdata.(varName) = value;

bv_saveData(subjectdata)