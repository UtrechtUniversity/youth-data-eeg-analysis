function bv_changeRootSubjectFile

eval('setPaths')
eval('setOptions')

sDirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
sNames = {sDirs.name};

for iSubjects = 1:length(sDirs)

    cSubject = sNames{iSubjects};
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    subjectdata = bv_check4data(subjectFolderPath);
    
    fnames = fieldnames(subjectdata.PATHS);
    subjectdata.PATHS.SUBJECTDIR = subjectFolderPath;
    
    for iField = 1:length(fnames)
        cField = fnames{iField};
        
        [~, filename, ext] = fileparts(subjectdata.PATHS.(cField));
        
        if strcmpi(ext, '.mat')
            if strcmpi(cField, 'PREPROC')
                subjectdata.PATHS.(cField) = [PATHS.PREPROC filesep filename ext];
            else
                subjectdata.PATHS.(cField) = [subjectdata.PATHS.SUBJECTDIR filesep filename ext];
            end
            fprintf('\t %s changed \n', cField)
            
        end
        
%         if ~exist(subjectdata.PATHS.(cField), 'file')
%             fprintf('\t %s does not exist, removed from subject file \n', cField)
%             subjectdata.PATHS = rmfield(subjectdata.PATHS, cField);
%         end
    end
    
%     % check existing files
%     exfiles = dir([subjectdata.PATHS.SUBJECTDIR filesep subjectdata.subjectName '*']);
%     
%     for iFile = 1:length(exfiles)
%         cFile = exfiles(iFile).name;
%         [~, filename, ext] = fileparts([subjectdata.PATHS.SUBJECTDIR filesep cFile]);
%         
%         addition = strsplit(filename, '_');
%         addition = upper(addition{end});
%         
%         if ismember(addition, fnames)
%             continue
%         end
%         
%         if strcmpi(ext, '.mat')
%             subjectdata.PATHS.(addition) = [subjectdata.PATHS.SUBJECTDIR filesep filename ext];
%             fprintf('\t %s changed \n', addition)
%         end
%         
%     end
%     
%     fieldsRequired = {'SUBJECTDIR', 'DATAFILE', 'HDRFILE'};
%     if not(all(ismember(fieldsRequired, fieldnames(subjectdata.PATHS))))
%         removingSubjects([], subjectdata.subjectName, 'missing files')
%         continue
%     end
    
    fprintf('\t saving Subject.mat file ...')
    save([subjectFolderPath filesep 'Subject.mat'], 'subjectdata')
    fprintf('done! \n')
    
end



