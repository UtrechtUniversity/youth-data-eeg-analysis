function [data, check] = bv_quickloadData(str, filestr)

eval('setPaths')
check = true;

if isnumeric(str)
    subjects = dir(PATHS.SUBJECTS);
    subjects = subjects([subjects.isdir] & ~ismember({subjects.name}, {'.', '..'}));
    subjects = subjects(~strcmp(fullfile(PATHS.SUBJECTS, {subjects.name}), PATHS.REMOVED));
    subjectNames = {subjects.name};
    subjectName = subjectNames{str};
else
    subjectFolders = dir(PATHS.SUBJECTS);
    subjectFolders = subjectFolders([subjectFolders.isdir] & ~ismember({subjectFolders.name}, {'.', '..'}));
    subjectFolders = subjectFolders(~strcmp(fullfile(PATHS.SUBJECTS, {subjectFolders.name}), PATHS.REMOVED));
    subjectFoldersName = {subjectFolders.name};
    subjectName = subjectFoldersName{ismember(subjectFoldersName, str)};
end

disp(subjectName)
subjectFolderPath = [PATHS.SUBJECTS filesep subjectName];

[~, check, data] = bv_check4data(subjectFolderPath, upper(filestr));
