function bv_rmFromSubjectfile(subjectName, varName)

eval('setOptions')
eval('setPaths')

subjectFolderPath = [PATHS.SUBJECTS filesep subjectName];
[subjectdata] = bv_check4data(subjectFolderPath);

subjectdata = rmfield(subjectdata, varName);

bv_saveData(subjectdata)