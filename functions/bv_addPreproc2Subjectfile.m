function bv_addPreproc2Subjectfile

eval('setPaths')

sDirs = dir(PATHS.SUBJECTS);
sDirs = sDirs([sDirs.isdir] & ~ismember({sDirs.name}, {'.', '..'}));
sDirs = sDirs(~strcmp(fullfile(PATHS.SUBJECTS, {sDirs.name}), PATHS.REMOVED));
sNames = {sDirs.name};
load([PATHS.SUMMARY filesep 'SubjectSummary'], 'subjectdatasummary')


for iSubjects = 1:length(sNames)
    cSubject = sNames{iSubjects};
    disp(cSubject)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep cSubject];
    subjectdata = bv_check4data(subjectFolderPath);
    
    preprocFile = dir([PATHS.PREPROC filesep subjectdata.subjectName '_PREPROC.mat']);
    
    if ~isempty(preprocFile)
        subjectdata.PATHS.PREPROC = [preprocFile.folder filesep preprocFile.name];
        subjectdata.analysisOrder = 'preproc';
    else
        subjectdata.PATHS.PREPROC = '';
        subjectdata.analysisOrder = '';
        removingSubjects([], cSubject, 'no preproc found')
        continue
    end
    
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata);
    bv_saveData(subjectdata)
    
end
