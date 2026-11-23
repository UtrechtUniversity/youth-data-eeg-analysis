%% POWER ESTIMATION PIPELINE WITHOUT SAVING INTERMEDIATE STEPS
% Overview script of the steps for frequency analysis and ROI power
% extraction, without saving intermediate steps: every subject goes through
% all steps in one go, handing the data from one step to the next in memory
% (see powerEstimates_standard for the steps and what they save). Only the
% power estimates and Subject.mat (which also holds the settings of the
% intermediate steps) are saved. Run after preprocessingData has completed
% for all subjects. A subject that fails a step is removed (see
% removingSubjects).
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

%% POWER ESTIMATES FOR EVERY SUBJECT
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject = subjectFolderNames{iSubjects};

    try
        % 1) EPOCH INTO SLIDING WINDOWS (loads the input from disk)
        cfg             = OPTIONS.EPOCH;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = bv_redefineTriallength(cfg);
        if isempty(data); continue; end

        % 2) CALCULATE ARTEFACTS IN EPOCHED DATA
        cfg             = OPTIONS.ARTFCTEPOCH;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        artefactdef = bv_createArtefactStruct(cfg, data);
        if isempty(artefactdef); continue; end     % subject was removed

        % 3) REMOVE ARTEFACT-CONTAMINATED EPOCHS
        cfg             = OPTIONS.CLEANEPOCHS;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        data = bv_cleanData(cfg, data, artefactdef);
        if isempty(data); continue; end

        % 4) CALCULATE FREQUENCY SPECTRA
        cfg             = OPTIONS.FREQUENCY;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'no';

        freq = bv_calculateFrequency(cfg, data);

        % 5) EXTRACT ROI POWER (the only output that is saved)
        cfg             = OPTIONS.ROIPOWER;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'yes';

        powerData = bv_extractROIPower(cfg, freq);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
end

%% UPDATE SUBJECT SUMMARY
% Subject.mat is always saved; here it is merged into the shared
% SubjectSummary.mat (also for the subjects that were removed on the way).
for iSubjects = 1:numel(subjectFolderNames)
    bv_syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT POWER SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectPowerSummary(OPTIONS.POWERSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

bv_collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
