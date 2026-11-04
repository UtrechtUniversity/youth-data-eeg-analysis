function bv_saveData(subjectdata, data, outputStr)
% Saves a subject's Subject.mat and, optionally, one data variable.
%
% With only subjectdata, Subject.mat is (re)saved in the subject folder.
% With data and outputStr as well, data is first saved as
% ``<subjectName>_<outputStr>.mat`` in the subject's preproc folder
% (``subjectdata.PATHS.PREPROCDIR``) and that file's path is registered in
% ``subjectdata.PATHS.(upper(outputStr))`` before Subject.mat is saved.
% The fields of subjectdata are put in canonical order first (see
% BV_ORDERSUBJECTFIELDS).
%
% The variable inside the saved data file is named after the variable the
% caller passed as data (e.g. ``data`` or ``artefactdef``), so data has to
% be passed as a plain variable, not as an expression or struct field.
% BV_CHECK4DATA loads the first variable in the file whatever its name.
%
% Args:
%     subjectdata (struct): Subject info. Needs ``subjectName``,
%         ``PATHS.SUBJECTDIR`` and, when saving data, ``PATHS.PREPROCDIR``
%         (all set by BV_CREATESUBJECTFOLDERS_NEWSTRUCT).
%     data (any, optional): Variable to save, passed as a plain variable.
%     outputStr (str): Label for the data file and its ``subjectdata.PATHS``
%         entry. Required when data is given.
%
% Example:
%     ```matlab
%     bv_saveData(subjectdata);                    % Subject.mat only
%     bv_saveData(subjectdata, data, 'PREPROC');   % data and Subject.mat
%     ```

if nargin > 1
    if nargin < 3 || isempty(outputStr)
        error('bv_saveData:noOutputStr', 'outputStr is required when saving data')
    end
    varName = inputname(2);
    if isempty(varName)
        error('bv_saveData:notAVariable', ...
            ['data must be passed as a plain variable (its name becomes the ' ...
            'variable name inside the saved file), not as an expression or struct field'])
    end

    eval([varName ' = data;'])

    filename = [subjectdata.subjectName '_' outputStr '.mat'];

    filePath = [subjectdata.PATHS.PREPROCDIR filesep filename];
    subjectdata.PATHS.(upper(outputStr)) = filePath;

    fprintf('\t saving %s ... ', filePath)
    save(filePath, varName)
    fprintf('done! \n')

end

subjectdata = bv_orderSubjectFields(subjectdata);

fprintf('\t saving Subject.mat ... ')
save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
fprintf('done! \n');
