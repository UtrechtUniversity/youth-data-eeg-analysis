%% NETWORK METRICS PIPELINE
% Overview script of the steps for connectivity and graph-metric calculations.
% Run after preprocessingData has completed for all subjects. Every step runs
% over all subjects before the next step starts and saves its output to the
% subject folder, so that a step can be redone without redoing the earlier
% ones. A subject for which a step fails is reported with a warning and is
% removed (moved to the removed directory), as in during preprocessing.
% After every step the subject's Subject.mat is merged into the shared
% SubjectSummary.mat, and the metric steps are followed by their
% cross-subject summary.
%
% Variants of this script (createNewAnalysis picks the one that matches
% your preprocessingData script):
%   networkMetrics_standard             this script
%   networkMetrics_parfor               same, in parallel
%   networkMetrics_withoutSave          one pass per subject, PLI handed
%                                       over in memory
%   networkMetrics_parfor_withoutSave   same, in parallel
%

%% settings
quiet = 'no';

%% ENSURE NETMET FOLDER EXISTS
% Subject folders created before the network-metrics feature have no netmet/
% subfolder or PATHS.NETMETDIR entry. Create and register them here so the
% steps below always have somewhere to write.
clear OPTIONS; setOptionsNetmet; setPaths

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    subjectFolderPath = fullfile(PATHS.SUBJECTS, subjectFolderNames{iSubjects});

    [subjectdata, check] = check4Data(subjectFolderPath);
    if ~check
        continue
    end

    subjectdata.PATHS.NETMETDIR = fullfile(subjectdata.PATHS.SUBJECTDIR, 'netmet');
    if ~exist(subjectdata.PATHS.NETMETDIR, 'dir')
        mkdir(subjectdata.PATHS.NETMETDIR);
    end
    save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata');
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE PLI CONNECTIVITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.PLICONNECTIVITY;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        connectivity = calculatePLI(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% CALCULATE FC STRENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.STRENGTH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        strength = calculateStrength(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT FC STRENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.STRENGTHSUMMARY);

%% CALCULATE SMALL-WORLD PROPENSITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.SWP;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        swp = calculateSWP(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT SWP SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.SWPSUMMARY);

%% CALCULATE Q MODULARITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.QMOD;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        qmod = calculateQModularity(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT Q MODULARITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.QMODSUMMARY);

%% CALCULATE CLUSTERING COEFFICIENT
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.CLUSTERING;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        clus = calculateClusteringWs(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT CLUSTERING SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.CLUSTERINGSUMMARY);

%% CALCULATE PATH LENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.PATHLENGTH;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        pathlen = calculatePathlengthWs(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT PATH LENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.PATHLENGTHSUMMARY);

%% CALCULATE BETWEENNESS CENTRALITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject     = subjectFolderNames{iSubjects};

    cfg             = OPTIONS.BC;
    cfg.currSubject = currSubject;
    cfg.quiet       = quiet;

    try
        bc = calculateBetweennessCentrality(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
    end
    syncSubjectSummary(currSubject);
end

%% COLLECT BETWEENNESS CENTRALITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.BCSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsNetmet

collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
