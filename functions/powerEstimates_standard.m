%% Power estimation pipeline
% Step-by-step script for frequency analysis and ROI power extraction.
% Run after preprocessingData has completed for all subjects.

%% CALCULATE FREQUENCY SPECTRA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.FREQUENCY;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    freq = bv_calculateFrequency(cfg);
end

%% EXTRACT ROI POWER
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.ROIPOWER;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    power = bv_extractROIPower(cfg);
end

%% COLLECT POWER SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectPowerSummary(OPTIONS.POWERSUMMARY);
