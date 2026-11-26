%% POWER ESTIMATION PIPELINE (parallel)
% Overview script of the steps for frequency analysis and ROI power
% extraction. Run after preprocessingData has completed for all subjects.
% Same steps as powerEstimates_standard: every step runs over all subjects
% before the next step starts and saves its output to the subject folder,
% but the subjects of a step are processed in parallel. A subject that
% fails a step is removed (see removingSubjects) and left out of the next
% steps.
%
% This is recommended if you run this script on a server or on any computer
% with multiple cores. Note that due to the parallelisation, output in the
% command window is generally limited.
%
% The shared SubjectSummary.mat is not written from the parallel workers
% (they would overwrite each other's rows). Instead, every step is followed
% by a serial pass that merges the subjects' Subject.mat into the summary.
%
% Variants of this script (createNewAnalysis picks the one that matches
% your preprocessingData script):
%   powerEstimates_standard             this script
%   powerEstimates_parfor               same, in parallel
%   powerEstimates_withoutSave          one pass per subject, only
%                                       the power estimates saved
%   powerEstimates_parfor_withoutSave   same, in parallel
%

%% settings
% maxWorkers limits the number of subjects processed at the same time (each
% worker holds the data of one subject in memory). [] uses all workers in
% the pool.
maxWorkers = [];
quiet      = 'yes';

pool = gcp;
if isempty(maxWorkers)
    maxWorkers = pool.NumWorkers;
end

%% EPOCH INTO SLIDING WINDOWS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.EPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = redefineTrialLength(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE ARTEFACTS IN EPOCHED DATA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ARTFCTEPOCH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        artefactdef = createArtefactStruct(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% REMOVE ARTEFACT-CONTAMINATED EPOCHS
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLEANEPOCHS;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        data = cleanData(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE FREQUENCY SPECTRA
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.FREQUENCY;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        freq = calculateFrequency(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% EXTRACT ROI POWER
clear OPTIONS; setOptionsPower

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.ROIPOWER;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        powerData = extractROIPower(cfg);
    catch ME
        removingSubjects([], currSubject, ME.message);
    end
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT POWER SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

collectPowerSummary(OPTIONS.POWERSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsPower

collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
