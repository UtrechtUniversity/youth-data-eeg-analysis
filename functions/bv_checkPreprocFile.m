function bv_checkPreprocFile

eval('setPaths')
eval('setOptions')

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*'])

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