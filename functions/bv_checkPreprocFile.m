function bv_checkPreprocFile

eval('setPaths')

subjectFolders = dir(PATHS.SUBJECTS);
subjectFolders = subjectFolders([subjectFolders.isdir] & ~ismember({subjectFolders.name}, {'.', '..'}));
subjectFolders = subjectFolders(~strcmp(fullfile(PATHS.SUBJECTS, {subjectFolders.name}), PATHS.REMOVED));

for i = 1:length(subjectFolders)
    disp(subjectFolders(i).name)
    [subjectdata] = bv_check4data([subjectFolders(i).folder filesep subjectFolders(i).name]);
    try 
        load(subjectdata.PATHS.PREPROC)
        fprintf('\t preproc loaded! \n')
    catch
        fprintf('\t PREPROC LOADING FAILED')
        removingSubjects([], subjectdata.subjectName, 'invalid preproc file')
    end
end