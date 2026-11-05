%% PREPROCESSING PIPELINE (parallel)
% Overview script of all the preprocessing steps needed before analysing EEG
% data. Same steps as PRERPROCESSINGDATA_STANDARD: every step runs over all
% subjects before the next step starts and saves its output to the subject
% folder, but the subjects of a step are processed in parallel. A subject
% that fails a step is removed (see REMOVINGSUBJECTS) and left out of the
% next steps.
%
% This is recommended if you run this script on any computer with
% multiple cores. Note that due to the parallelisation, feedback in the
% command window is generally limited. It is therefore not recommended to
% use this script if you are new to this pipeline.
%
% The shared SubjectSummary.mat is not written from the parallel workers
% (they would overwrite each other's rows). Instead, every step is followed
% by a serial pass that merges the subjects' Subject.mat into the summary.

%% start parallel pool
% maxWorkers limits the number of subjects processed at the same time (each
% worker holds the EEG data of one subject in memory). [] uses all workers
% in the pool.
maxWorkers = [];
quiet      = 'yes';

pool = gcp;
if isempty(maxWorkers)
    maxWorkers = pool.NumWorkers;
end

%% setup subject folders
clear OPTIONS; setOptions

cfg = OPTIONS.CREATEFOLDERS;
bv_createSubjectFolders_NewStruct(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.PREPROC;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_preprocResample(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        artefactdef = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_removeChannels(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_preprocResample(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        artefactdef = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% REMOVE TRIALS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% APPEND DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_appendfieldtripdata(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptions

bv_collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
