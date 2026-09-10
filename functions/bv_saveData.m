function bv_saveData(subjectdata, data, outputStr)

global PATHS

if nargin > 1
    eval([inputname(2) ' = data;'])

    filename = [subjectdata.subjectName '_' outputStr '.mat'];

    filePath = [subjectdata.PATHS.PREPROCDIR filesep filename];
    subjectdata.PATHS.(upper(outputStr)) = filePath;
    
    fprintf('\t saving %s ... ', filePath)
    save(filePath, inputname(2))
    fprintf('done! \n')
    
end

subjectdata = bv_orderSubjectFields(subjectdata);

fprintf('\t saving Subject.mat ... ')
save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
fprintf('done! \n');