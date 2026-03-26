function [data, check] = bv_quickloadData(str, filestr)

eval('setOptions')
eval('setPaths')
check = true;

if isnumeric(str)
    subjects = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
    subjectNames = {subjects.name};
    subjectName = subjectNames{str};
else
    subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
    subjectFoldersName = {subjectFolders.name};
    subjectName = subjectFoldersName{ismember(subjectFoldersName, str)};
end

disp(subjectName)
subjectFolderPath = [PATHS.SUBJECTS filesep subjectName];

[~, check, data] = bv_check4data(subjectFolderPath, upper(filestr));
