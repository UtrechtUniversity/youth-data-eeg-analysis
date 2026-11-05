%% PREPROCESSING PIPELINE
% Overview script of all the preprocessing steps needed before analysing EEG
% data. Every step runs over all subjects before the next step starts and
% saves its output to the subject folder, so that a step can be redone
% without redoing the earlier ones. A subject that fails a step is removed
% (see REMOVINGSUBJECTS) and left out of the next steps. After every step
% the subject's Subject.mat is merged into the shared SubjectSummary.mat.
%
% Variants of this script (BV_CREATENEWANALYSIS picks one):
%   preprocessingData_standard                      this script
%   preprocessingData_standard_parfor               same, in parallel
%   preprocessingData_standard_withoutSave          one pass per subject,
%                                                   no intermediate files
%   preprocessingData_standard_withoutSave_parfor   same, in parallel

%% setup subject folders
clear OPTIONS; setOptions
cfg = OPTIONS.CREATEFOLDERS;
bv_createSubjectFolders_NewStruct(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
        currSubject = subjectFolderNames{iSubjects};

        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'no';

        try
            data = bv_preprocResample(cfg);
        catch ME
            removingSubjects([], currSubject, ME.message);
        end
        bv_syncSubjectSummary(currSubject);
end

%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.quiet       = 'no';
    cfg.currSubject = currSubject;

    try
        artefactdef = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_removeChannels(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_preprocResample(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        artefactdef     = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% REMOVE TRIALS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% APPEND DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_appendfieldtripdata(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptions

bv_collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
