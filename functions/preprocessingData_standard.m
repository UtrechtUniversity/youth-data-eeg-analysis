%% BEFORE WE START'
% This is an overview script of all the preprocessing steps needed to be
% taken before analyzing EEG data.
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
end
