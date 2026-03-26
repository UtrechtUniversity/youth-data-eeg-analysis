function bv_autoConcatenateSubjects(cfg)

inputStr = ft_getopt(cfg, 'inputStr', 'preproc');

eval('setOptions');
eval('setPaths');

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};

subjectFolderNames2 = cellfun(@(v) v(1:6), subjectFolderNames, 'Un', 0)';
uniqueSubjectFolderNames = unique(subjectFolderNames2, 'stable');

occurrenceSubjectNames = cellfun(@(x) ...
    sum(ismember(subjectFolderNames2,x)),uniqueSubjectFolderNames,'Un',0);

subjectsToConcatenate = uniqueSubjectFolderNames([occurrenceSubjectNames{:}] >= 2);

fprintf('%1.0f subjects found to be concatenated \n', length(subjectsToConcatenate))
for i = 1:length(subjectsToConcatenate)
    cSubjectName = subjectsToConcatenate{i};
    disp(cSubjectName)
    curr2bConcatenated = subjectFolderNames(contains(subjectFolderNames,subjectsToConcatenate{i}));
    
    
    subjectFolderPath1 = [PATHS.SUBJECTS filesep curr2bConcatenated{1}];
    subjectFolderPath2 = [PATHS.SUBJECTS filesep curr2bConcatenated{2}];
    [subjectdataIn1,dataIn1] = bv_check4data(subjectFolderPath1, inputStr);
    [subjectdataIn2,dataIn2] = bv_check4data(subjectFolderPath2, inputStr);
    
    removingSubjects([], subjectdataIn1.subjectName, 'concatenating data')
    removingSubjects([], subjectdataIn2.subjectName, 'concatenating data')
    delete(subjectdataIn1.PATHS.PREPROC)
    delete(subjectdataIn2.PATHS.PREPROC)
    
    cfg = [];
    evalc('data = ft_appenddata(cfg,dataIn1, dataIn2);');
    
    filename = [cSubjectName, '_' inputStr '.mat'];
    save2folder = fileparts(subjectdataIn1.PATHS.(upper(inputStr)));
    fprintf('\t saving %s ... \n', filename)
    fprintf('\t \t to %s ... ', save2folder)
    save([save2folder filesep filename], 'data')
    fprintf('done! \n')
    
    newSubjectFolderPath = [PATHS.SUBJECTS filesep subjectsToConcatenate{i}];
    if ~exist(newSubjectFolderPath,'dir')
        mkdir(newSubjectFolderPath); % create, if necessary, individual subject folder
    end
    
    subjectdata = [];
    subjectdata.subjectName = cSubjectName;
    subjectdata.date = date;
    subjectdata.PATHS.SUBJECTDIR = newSubjectFolderPath;
    subjectdata.PATHS.PREPROC = [save2folder filesep filename];
    
    fprintf('\t saving new subjectdata for subject: %s ... ', subjectdata.subjectName)
    save([newSubjectFolderPath filesep 'Subject.mat'], 'subjectdata')
    fprintf('done! \n')
    clear subjectdata
    
end


