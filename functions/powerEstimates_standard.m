%% Power estimation pipeline
% Step-by-step script for frequency analysis and ROI power extraction.
% Run after preprocessingData has completed for all subjects.

%% EPOCH INTO SLIDING WINDOWS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.EPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_redefineTriallength(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

%% CALCULATE ARTEFACTS IN EPOCHED DATA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.ARTFCTEPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        artefactdef = bv_createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

%% REMOVE ARTEFACT-CONTAMINATED EPOCHS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.CLEANEPOCHS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    try
        data = bv_cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

%% CALCULATE FREQUENCY SPECTRA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.FREQUENCY;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    freq = bv_calculateFrequency(cfg);
    bv_syncSubjectSummary(currSubject);
end

%% EXTRACT ROI POWER
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject     = subjectFolderNames{iSubjects};
    cfg             = OPTIONS.ROIPOWER;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';

    power = bv_extractROIPower(cfg);
    bv_syncSubjectSummary(currSubject);
end

%% COLLECT POWER SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectPowerSummary(OPTIONS.POWERSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
