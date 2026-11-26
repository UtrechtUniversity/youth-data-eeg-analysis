%% PREPROCESSING PIPELINE
% Overview script of all the preprocessing steps needed before analysing EEG
% data. Every step runs over all subjects before the next step starts and
% saves its output to the subject folder, so that a step can be redone
% without redoing the earlier ones. A subject that fails a step is removed
% (see REMOVINGSUBJECTS) and left out of the next steps. After every step
% the subject's Subject.mat is merged into the shared SubjectSummary.mat.
%
% Variants of this script (CREATENEWANALYSIS picks one):
%   preprocessingData_standard             this script
%   preprocessingData_parfor               same, in parallel
%   preprocessingData_withoutSave          one pass per subject,
%                                          no intermediate files
%   preprocessingData_parfor_withoutSave   same, in parallel

%% setup subject folders
clear OPTIONS; setOptionsPreproc
cfg = OPTIONS.CREATEFOLDERS;
createSubjectFolders(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
        currSubject = subjectFolderNames{iSubjects};

        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'no';

        try
            data = preprocResample(cfg);
        catch ME
            removingSubjects([], currSubject, ME.message);
        end
        syncSubjectSummary(currSubject);
end

%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.quiet       = 'no';
    cfg.currSubject = currSubject;

    try
        artefactdef = createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = removeChannels(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = preprocResample(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        artefactdef     = createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% REMOVE TRIALS
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% APPEND DATA
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = appendFieldtripData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPreproc

collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
