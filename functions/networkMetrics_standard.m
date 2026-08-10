%% Network metrics pipeline
% Step-by-step script for connectivity and graph-metric calculation.
% Run after preprocessingData has completed for all subjects.

%% ENSURE NETMET FOLDER EXISTS
% Subject folders created before the network-metrics feature have no netmet/
% subfolder or PATHS.NETMETDIR entry. Create and register them here so the
% steps below always have somewhere to write.
clear OPTIONS; setOptionsNetmet; setPaths

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    subjectFolderPath = fullfile(PATHS.SUBJECTS, subjectFolderNames{iSubjects});

    [subjectdata, check] = bv_check4data(subjectFolderPath);
    if ~check
        continue
    end

    subjectdata.PATHS.NETMETDIR = fullfile(subjectdata.PATHS.SUBJECTDIR, 'netmet');
    if ~exist(subjectdata.PATHS.NETMETDIR, 'dir')
        mkdir(subjectdata.PATHS.NETMETDIR);
    end
    save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata');
end

%% CALCULATE PLI CONNECTIVITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.PLICONNECTIVITY;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    connectivity = bv_calculatePLI(cfg);
end

%% CALCULATE FC STRENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.STRENGTH;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    strength = bv_calculateStrength(cfg);
end

%% COLLECT FC STRENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.STRENGTHSUMMARY);

%% CALCULATE SMALL-WORLD PROPENSITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.SWP;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    swp = bv_calculateSWP(cfg);
end

%% COLLECT SWP SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.SWPSUMMARY);

%% CALCULATE Q MODULARITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.QMOD;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    qmod = gr_calculateQModularity(cfg);
end

%% COLLECT Q MODULARITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.QMODSUMMARY);

%% CALCULATE CLUSTERING COEFFICIENT
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.CLUSTERING;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    clus = gr_calculateClusteringWs(cfg);
end

%% COLLECT CLUSTERING SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.CLUSTERINGSUMMARY);

%% CALCULATE PATH LENGTH
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.PATHLENGTH;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    pathlen = gr_calculatePathlengthWs(cfg);
end

%% COLLECT PATH LENGTH SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.PATHLENGTHSUMMARY);

%% CALCULATE BETWEENNESS CENTRALITY
clear OPTIONS; setOptionsNetmet

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.BC;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';

    bc = gr_calculateBetweennessCentrality(cfg);
end

%% COLLECT BETWEENNESS CENTRALITY SUMMARY (cross-subject)
clear OPTIONS; setOptionsNetmet

bv_collectNetmetSummary(OPTIONS.BCSUMMARY);
