%% PREPROCESSING PIPELINE WITHOUT SAVING INTERMEDIATE STEPS
% Overview script of all the preprocessing steps needed before analysing EEG
% data, without saving intermediate steps: every subject goes through all
% steps in one go, handing the data from one step to the next in memory
% (see PREPROCESSINGDATA_STANDARD for the steps and what they save). Only
% the final appended data and Subject.mat (which also holds the results of
% the intermediate steps, e.g. the removed channels) are saved. This is
% generally not recommended, but if you have limited space on your
% harddrive, this is the script to use. A subject that fails a step is
% removed (see REMOVINGSUBJECTS).

%% settings
quiet = 'no';

%% setup subject folders
clear OPTIONS; setOptionsPreproc

cfg = OPTIONS.CREATEFOLDERS;
createSubjectFolders(cfg);

%% PREPROCESS EVERY SUBJECT
clear OPTIONS; setOptionsPreproc

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject = subjectFolderNames{iSubjects};

    try
        % 1) PREPROCESSING AND RESAMPLING
        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = preprocResample(cfg);
        if isempty(data); continue; end     % subject was removed

        % 2) CALCULATE ARTEFACTS IN PREPROC DATA
        cfg             = OPTIONS.ARTFCTPREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        artefactdef = createArtefactStruct(cfg, data);
        if isempty(artefactdef); continue; end

        % 3) SET CHANNELS TO REMOVE
        % The flagged channels are written to Subject.mat, from where the
        % next preprocessing step reads them.
        cfg             = OPTIONS.RMCHANNELS;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = removeChannels(cfg, data, artefactdef);
        if isempty(data); continue; end

        % 4) PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
        % Reads the raw data again, so the data of step 1 is not needed.
        cfg             = OPTIONS.REREF;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = preprocResample(cfg);
        if isempty(data); continue; end

        % 5) CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
        cfg             = OPTIONS.ARTFCTRMCHANNELS;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        artefactdef = createArtefactStruct(cfg, data);
        if isempty(artefactdef); continue; end

        % 6) REMOVE TRIALS
        cfg             = OPTIONS.CLEANED;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = cleanData(cfg, data, artefactdef);
        if isempty(data); continue; end

        % 7) APPEND DATA (the only output that is saved)
        cfg             = OPTIONS.APPENDED;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'yes';

        data = appendFieldtripData(cfg, data);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
end

%% UPDATE SUBJECT SUMMARY
% Subject.mat is always saved; here it is merged into the shared
% SubjectSummary.mat (also for the subjects that were removed on the way).
for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
