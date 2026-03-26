function [nTrls, subjectFolderNames] = bv_countTrials(cfg)

inputStr = ft_getopt(cfg, 'inputStr');

eval('setOptions');
eval('setPaths');

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};

nSubjects = length(subjectFolderNames);
nTrls = zeros(1, length(subjectFolderNames));

for i = 1:nSubjects
    
    currSubject = subjectFolderNames{i};
    
    disp(currSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    
    nTrls(i) = length(data.trial);
    fprintf('\t %1.0f trials found ...  \n', nTrls(i))
end