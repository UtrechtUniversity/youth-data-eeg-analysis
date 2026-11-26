%% NETWORK METRICS PIPELINE WITHOUT SAVING INTERMEDIATE STEPS
% Overview script of the steps for connectivity and graph-metric calculations,
% without saving intermediate steps: every subject goes through all steps in
% one go, and the PLI connectivity is handed to the metric functions in
% memory (see networkMetrics_standard for the steps and what they save). The
% PLI connectivity is saved as well; there are no other intermediate files. Run after preprocessingData
% has completed for all subjects. A subject for which a step fails is
% reported with a warning and removed (moved to the removed directory).
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

%% NETWORK METRICS FOR EVERY SUBJECT
clear OPTIONS; setOptionsNetmet

% metrics to calculate: name of the OPTIONS field, and the function
metrics = {
    'STRENGTH',   @calculateStrength
    'SWP',        @calculateSWP
    'QMOD',       @calculateQModularity
    'CLUSTERING', @calculateClusteringWs
    'PATHLENGTH', @calculatePathlengthWs
    'BC',         @calculateBetweennessCentrality
    };

[startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

for iSubjects = 1:numel(subjectFolderNames)
    currSubject = subjectFolderNames{iSubjects};

    % 1) CALCULATE PLI CONNECTIVITY (loads the clean-trial definitions from
    % disk). It is saved and handed over in memory. As everywhere, the
    % overwrite setting in OPTIONS.PLICONNECTIVITY is respected: if the PLI
    % file exists and overwrite is 'no', nothing is calculated and the metrics
    % below load the saved file instead.
    try
        cfg             = OPTIONS.PLICONNECTIVITY;
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'yes';

        connectivity = calculatePLI(cfg);
    catch ME
        warning('%s: %s', currSubject, ME.message);
        removingSubjects([], currSubject, ME.message);
        continue
    end

    % 2) CALCULATE THE NETWORK METRICS, from the PLI connectivity in memory.
    % A subject for which a metric fails is removed.
    for iMetric = 1:size(metrics, 1)
        cfg             = OPTIONS.(metrics{iMetric, 1});
        cfg.currSubject = currSubject;
        cfg.quiet       = quiet;
        cfg.saveData    = 'yes';

        try
            if isempty(connectivity)
                result = metrics{iMetric, 2}(cfg);               % load the saved PLI file
            else
                result = metrics{iMetric, 2}(cfg, connectivity); % hand over
            end
        catch ME
            warning('%s (%s): %s', currSubject, metrics{iMetric, 1}, ME.message);
            removingSubjects([], currSubject, ME.message);
            break
        end
    end
end

%% UPDATE SUBJECT SUMMARY
% Subject.mat is always saved; here it is merged into the shared
% SubjectSummary.mat.
for iSubjects = 1:numel(subjectFolderNames)
    syncSubjectSummary(subjectFolderNames{iSubjects});
end

%% COLLECT METRIC SUMMARIES (cross-subject)
clear OPTIONS; setOptionsNetmet

collectNetmetSummary(OPTIONS.STRENGTHSUMMARY);
collectNetmetSummary(OPTIONS.SWPSUMMARY);
collectNetmetSummary(OPTIONS.QMODSUMMARY);
collectNetmetSummary(OPTIONS.CLUSTERINGSUMMARY);
collectNetmetSummary(OPTIONS.PATHLENGTHSUMMARY);
collectNetmetSummary(OPTIONS.BCSUMMARY);

%% COLLECT SUBJECT SUMMARY (cross-subject CSV)
clear OPTIONS; setOptionsNetmet

collectSubjectSummary(OPTIONS.SUBJECTSUMMARY);
