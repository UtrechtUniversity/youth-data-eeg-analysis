%% NETWORK METRICS PIPELINE (parallel)
% Overview script of the steps for connectivity and graph-metric calculations.
% Run after preprocessingData has completed for all subjects. Same steps as
% networkMetrics_standard: every step runs over all subjects before the next
% step starts and saves its output to the subject folder, but the subjects
% of a step are processed in parallel. A subject for which a step fails is
% reported with a warning and removed (moved to the removed directory).
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
%   networkMetrics_standard             this script
%   networkMetrics_parfor               same, in parallel
%   networkMetrics_withoutSave          one pass per subject, PLI handed
%                                       over in memory
%   networkMetrics_parfor_withoutSave   same, in parallel
%

%% settings
% maxWorkers limits the number of subjects processed at the same time (each
% worker holds the PLI connectivity of one subject in memory). [] uses all
% workers in the pool.
maxWorkers = [];
quiet      = 'yes';

pool = gcp;
if isempty(maxWorkers)
    maxWorkers = pool.NumWorkers;
end

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

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% CALCULATE FC STRENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT FC STRENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.STRENGTHSUMMARY);

%% CALCULATE SMALL-WORLD PROPENSITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT SWP SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.SWPSUMMARY);

%% CALCULATE Q MODULARITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT Q MODULARITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.QMODSUMMARY);

%% CALCULATE CLUSTERING COEFFICIENT
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT CLUSTERING SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.CLUSTERINGSUMMARY);

%% CALCULATE PATH LENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT PATH LENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.PATHLENGTHSUMMARY);

%% CALCULATE BETWEENNESS CENTRALITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

parfor (iSubjects = 1:numel(subjectFolderNames), maxWorkers)
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
end

for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT BETWEENNESS CENTRALITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.BCSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsNetmet

collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
