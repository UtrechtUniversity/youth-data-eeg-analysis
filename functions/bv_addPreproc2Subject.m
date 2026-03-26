function bv_addPreproc2Subject

eval('setPaths')
eval('setOptions')

sDirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
sNames = {sDirs.name};

preprocFiles = dir([PATHS.PREPROC filesep '*.mat']);
preprocFileNames = {preprocFiles.name};

for iSubject = 1:length(sNames)
    cSubject = sNames{iSubject};
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    subjectdata = bv_check4data(subjectFolderPath);
    
    currPreprocFile = preprocFileNames(contains(preprocFileNames, cSubject));
    if length(currPreprocFile) > 1
        tmp = cellfun(@(x) strsplit(x, '_'), currPreprocFile, 'Un', 0);
        tmp2 = cellfun(@(v) v{1}, tmp, 'Un', 0);
        currPreprocFile = currPreprocFile(ismember(tmp2,cSubject));
        
        if length(currPreprocFile) > 1
            error('Too many preproc files found')
        end
    end
    
    path2CurrPreprocFile = [PATHS.PREPROC filesep currPreprocFile{:}];
    if ~isempty(currPreprocFile) && exist(path2CurrPreprocFile, 'file')
        fprintf('\t preproc file found %s ...\n', currPreprocFile{:})
        subjectdata.PATHS.PREPROC = path2CurrPreprocFile;
    else
        error('no preproc file found')
    end
    
    fprintf('\t saving Subject.mat file ...')
    save([subjectFolderPath filesep 'Subject.mat'], 'subjectdata')
    fprintf('done! \n')
    
end

