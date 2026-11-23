%% POWER ESTIMATION PIPELINE
% Overview script of the steps for frequency analysis and ROI power
% extraction. Run after preprocessingData has completed for all subjects.
% Every step runs over all subjects before the next step starts and saves
% its output to the subject folder, so that a step can be redone without
% redoing the earlier ones. A subject that fails a step is removed (see
% removingSubjects) and left out of the next steps. After every step the
% subject's Subject.mat is merged into the shared SubjectSummary.mat.
%
% Variants of this script (bv_createNewAnalysis picks the one that matches
% your preprocessingData script):
%   powerEstimates_standard                      this script
%   powerEstimates_standard_parfor               same, in parallel
%   powerEstimates_standard_withoutSave          one pass per subject, only
%                                                the power estimates saved
%   powerEstimates_standard_withoutSave_parfor   same, in parallel
%

%% settings
quiet = 'no';

%% EPOCH INTO SLIDING WINDOWS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.EPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_redefineTriallength(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% CALCULATE ARTEFACTS IN EPOCHED DATA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTEPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        artefactdef = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% REMOVE ARTEFACT-CONTAMINATED EPOCHS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLEANEPOCHS;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = bv_cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% CALCULATE FREQUENCY SPECTRA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.FREQUENCY;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        freq = bv_calculateFrequency(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% EXTRACT ROI POWER
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ROIPOWER;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        powerData = bv_extractROIPower(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
    bv_syncSubjectSummary(currSubject);
end

%% COLLECT POWER SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectPowerSummary(OPTIONS.POWERSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
