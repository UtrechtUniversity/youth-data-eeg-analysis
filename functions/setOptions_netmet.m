%% Settings for Network Metrics
% This file holds the settings of the network-metric analysis. A copy is
% placed in every new analysis folder (as setOptionsNetmet.m). Adjust the
% values to the right of the '=' signs before running networkMetrics.m; the
% text after the '%' explains each setting.
%
% The analysis first calculates functional connectivity between all pairs of
% channels (the phase lag index, PLI, per epoch and frequency band) and then
% summarises each subject's connectivity network with several metrics:
% connection strength, small-world propensity, modularity, clustering
% coefficient, path length measures and betweenness centrality. Each metric
% is then collected over all subjects in a summary file.
%
% The tag at the start of each comment shows what kind of value is expected:
%   'string'    text between quotes, e.g. 'yes'
%   [ number ]  a number, or several numbers in square brackets
%   { cell }    a list of items in curly braces, e.g. {'EEG'}
%   struct      a group of related settings (defined just above)
% Names in FieldTrip style (ft_...) refer to the FieldTrip function that uses
% the setting; they are only mentioned for reference.
%
% Settings for the subject being processed (subject name, command-window
% output) are filled in by the scripts and are not listed here. The
% docstring of the function named above each block describes every setting
% in full.

% Load the preprocessing settings from setOptionsPreproc.m, which this file builds
% on (e.g. the re-referencing settings and the epoch length).
setOptionsPreproc;

%% General options
OPTIONS.saveData    = 'yes';      % 'string': Save the results of the steps in the subject folders: 'yes' or 'no' (stored in subjectdata)
OPTIONS.pathsScript = 'setPaths'; % 'string': Name of the paths script (normally leave as is)
OPTIONS.triallength = 3;          % [ number ]: Length (seconds) of the epochs the connectivity metric (PLI) is calculated on

%% PLI connectivity options
% Calculates the phase lag index (PLI), a measure of the connectivity between
% two channels, for every pair of channels, epoch and frequency band.
% See calculatePLI
%
% Frequency bands for the connectivity, as [lowest highest] in Hz. The signal
% is band-pass filtered to each band before the PLI is calculated, and all
% network metrics are reported per band. You can add, remove or rename bands;
% the order below is the column order of the results. These are the same
% bands as in setOptionsPower.m (and the defaults of the functions); keep
% them in sync if you change them.
freqBands = struct;
freqBands.delta       = [1 3];   % Hz
freqBands.theta       = [4 7];   % Hz
freqBands.alpha       = [8 12];  % Hz
freqBands.beta        = [13 25]; % Hz
freqBands.gamma       = [26 35]; % Hz
freqBands.infantTheta = [3 6];   % Hz
freqBands.infantAlpha = [6 9];   % Hz
freqBands.total       = [1 35];  % Hz

% Artefact limits for the epochs. The epochs are cut like the epochs of the
% power step (same length and overlap, from the same clean data) and checked
% against the same limits as in setOptionsPower.m: an epoch that exceeds any
% limit is discarded for all frequency bands. We suggest to keep them in sync.
epochLims = struct;
epochLims.abs      = 250;   % [ number ]: largest allowed absolute amplitude (uV)
epochLims.flatline = 0.1;   % [ number ]: flat-signal measure (1 ./ SD.^2); higher = flatter
epochLims.kurtosis = 10;    % [ number ]: peakedness of the signal distribution
epochLims.variance = 2000;  % [ number ]: variance of the signal (uV^2)

OPTIONS.PLICONNECTIVITY.inputName      = 'APPEND';                             % 'string': Saved result the epochs are cut from (the joined clean data, as for the power epochs)
OPTIONS.PLICONNECTIVITY.outputName     = ['PLI' num2str(OPTIONS.triallength)]; % 'string': Name the connectivity is saved under (PLI + epoch length, e.g. PLI3)
OPTIONS.PLICONNECTIVITY.saveData       = OPTIONS.saveData;                     % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.PLICONNECTIVITY.pathsFcn       = OPTIONS.pathsScript;                  % 'string': Name of the paths script (normally leave as is)
OPTIONS.PLICONNECTIVITY.overwrite      = 'no';                                 % 'string': 'yes' = recalculate and replace an existing PLI file; 'no' = keep it and skip the calculation
OPTIONS.PLICONNECTIVITY.freqBands      = freqBands;                            % struct: Frequency bands in Hz (defined above)
OPTIONS.PLICONNECTIVITY.triallength    = OPTIONS.triallength;                  % [ number ]: Length (seconds) of the epochs the connectivity is calculated on (as in setOptionsPower.m)
OPTIONS.PLICONNECTIVITY.overlap        = 2/3;                                  % [ number ]: Overlap between consecutive epochs as a fraction (0-1); 2/3 of 3 s epochs = a new epoch every 1 s (as in setOptionsPower.m); 0 = no overlap
OPTIONS.PLICONNECTIVITY.cleanEpochs    = 'no';                                 % 'string': Remove the noisy epochs, those with an artefact measure above a limit in epochLims: 'yes' or 'no' ('no' keeps every epoch)
OPTIONS.PLICONNECTIVITY.lims           = epochLims;                            % struct: Thresholds above which an epoch is discarded (defined above)
OPTIONS.PLICONNECTIVITY.minEpochs      = [];                                   % [ number ]: Minimum number of clean epochs a subject needs; a subject with fewer is removed. [] = no minimum (a subject is then only removed when no clean epoch is left)
OPTIONS.PLICONNECTIVITY.ntrials        = 'all';                                % 'string': Number of epochs to use per subject; 'all' = every epoch
OPTIONS.PLICONNECTIVITY.condition      = 'all';                                % 'string': Trigger codes of the conditions to include; 'all' = every condition
OPTIONS.PLICONNECTIVITY.keeptrials     = 'yes';                                % 'string': Keep the connectivity of every epoch (required by the network metrics): 'yes' or 'no'
OPTIONS.PLICONNECTIVITY.preprocOptions = OPTIONS.REREF;                        % struct: Preprocessing settings used to re-read the raw recording before the PLI is calculated (the REREF step of setOptionsPreproc.m; normally leave as is)

%% ROI definitions (shared by the network metrics)
% Regions of interest: each name is followed by the channels it consists of.
ROI = struct;
ROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
ROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
ROI.RightFrontal  = {'F4','F8','FC6','FC2'};
ROI.Central       = {'C3','C4','CP1','CP2','Cz'};
ROI.LeftParietal  = {'T7','CP5','P7','P3'};
ROI.RightParietal = {'T8','CP6','P8','P4'};
ROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

%% FC strength options
% Functional connectivity strength: the mean connectivity (PLI) between the
% channels of the network. See calculateStrength
OPTIONS.STRENGTH.inputName       = OPTIONS.PLICONNECTIVITY.outputName; % 'string': Saved PLI connectivity file the strength is calculated from
OPTIONS.STRENGTH.outputName      = 'STRENGTH';                         % 'string': Name the strength results are saved under
OPTIONS.STRENGTH.conditions      = [129 139];                          % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.STRENGTH.conditionLabels = {'NonSocial', 'Social'};            % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.STRENGTH.computeGlobal   = 'yes';                              % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.STRENGTH.computeROI      = 'yes';                              % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.STRENGTH.ROI             = ROI;                                % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.STRENGTH.spctrmfield     = 'plispctrm';                        % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.STRENGTH.saveData        = OPTIONS.saveData;                   % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.STRENGTH.pathsFcn        = OPTIONS.pathsScript;                % 'string': Name of the paths script (normally leave as is)
OPTIONS.STRENGTH.overwrite       = 'yes';                              % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% FC strength summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.STRENGTHSUMMARY.inputName  = OPTIONS.STRENGTH.outputName; % 'string': Saved per-subject strength results to collect
OPTIONS.STRENGTHSUMMARY.outputName = 'strength_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.STRENGTHSUMMARY.format     = 'both';                      % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.STRENGTHSUMMARY.pathsFcn   = OPTIONS.pathsScript;         % 'string': Name of the paths script (normally leave as is)

%% Small-world propensity options
% Small-world propensity: how strongly the network combines clustered local
% connections with short paths between channels (small-world organisation),
% in a way that is comparable between networks of different density.
% See calculateSWP
OPTIONS.SWP.inputName       = OPTIONS.PLICONNECTIVITY.outputName; % 'string': Saved PLI connectivity file the small-world propensity is calculated from
OPTIONS.SWP.outputName      = 'SWP';                              % 'string': Name the small-world propensity results are saved under
OPTIONS.SWP.conditions      = [129 139];                          % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.SWP.conditionLabels = {'NonSocial', 'Social'};            % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.SWP.computeGlobal   = 'yes';                              % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.SWP.computeROI      = 'yes';                              % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.SWP.ROI             = ROI;                                % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.SWP.spctrmfield     = 'plispctrm';                        % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.SWP.saveData        = OPTIONS.saveData;                   % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.SWP.pathsFcn        = OPTIONS.pathsScript;                % 'string': Name of the paths script (normally leave as is)
OPTIONS.SWP.overwrite       = 'yes';                              % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% SWP summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.SWPSUMMARY.inputName  = OPTIONS.SWP.outputName; % 'string': Saved per-subject small-world propensity results to collect
OPTIONS.SWPSUMMARY.outputName = 'swp_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.SWPSUMMARY.format     = 'both';                 % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.SWPSUMMARY.pathsFcn   = OPTIONS.pathsScript;    % 'string': Name of the paths script (normally leave as is)

%% Q modularity options
% Modularity (Q): how well the network divides into modules (groups of
% channels that are strongly connected to each other and weakly to the rest).
% Needs the Brain Connectivity Toolbox that comes with FieldTrip.
% See calculateQModularity
OPTIONS.QMOD.inputName       = OPTIONS.PLICONNECTIVITY.outputName; % 'string': Saved PLI connectivity file the modularity is calculated from
OPTIONS.QMOD.outputName      = 'QMOD';                             % 'string': Name the modularity results are saved under
OPTIONS.QMOD.conditions      = [129 139];                          % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.QMOD.conditionLabels = {'NonSocial', 'Social'};            % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.QMOD.computeGlobal   = 'yes';                              % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.QMOD.computeROI      = 'yes';                              % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.QMOD.ROI             = ROI;                                % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.QMOD.edgeType        = 'weighted';                         % 'string': 'weighted' = use the connection strengths (rescaled to 0-1); 'binary' = treat the network as unweighted (see the function help)
OPTIONS.QMOD.gamma           = 1;                                  % [ number ]: Resolution of the community detection: 1 = classic modularity; higher gives more, smaller modules
OPTIONS.QMOD.spctrmfield     = 'plispctrm';                        % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.QMOD.saveData        = OPTIONS.saveData;                   % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.QMOD.pathsFcn        = OPTIONS.pathsScript;                % 'string': Name of the paths script (normally leave as is)
OPTIONS.QMOD.overwrite       = 'yes';                              % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Q modularity summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.QMODSUMMARY.inputName  = OPTIONS.QMOD.outputName; % 'string': Saved per-subject modularity results to collect
OPTIONS.QMODSUMMARY.outputName = 'qmod_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.QMODSUMMARY.format     = 'both';                  % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.QMODSUMMARY.pathsFcn   = OPTIONS.pathsScript;     % 'string': Name of the paths script (normally leave as is)

%% Clustering coefficient options
% Clustering coefficient: how strongly the neighbours of a channel are
% connected to each other (local connectedness), averaged over channels.
% Needs the Brain Connectivity Toolbox that comes with FieldTrip.
% See calculateClusteringWs
OPTIONS.CLUSTERING.inputName       = OPTIONS.PLICONNECTIVITY.outputName; % 'string': Saved PLI connectivity file the clustering coefficient is calculated from
OPTIONS.CLUSTERING.outputName      = 'CLUSTERING';                       % 'string': Name the clustering coefficient results are saved under
OPTIONS.CLUSTERING.conditions      = [129 139];                          % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.CLUSTERING.conditionLabels = {'NonSocial', 'Social'};            % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.CLUSTERING.computeGlobal   = 'yes';                              % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.CLUSTERING.computeROI      = 'yes';                              % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.CLUSTERING.ROI             = ROI;                                % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.CLUSTERING.edgeType        = 'weighted';                         % 'string': 'weighted' = use the connection strengths (rescaled to 0-1); 'binary' = treat the network as unweighted (see the function help)
OPTIONS.CLUSTERING.spctrmfield     = 'plispctrm';                        % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.CLUSTERING.saveData        = OPTIONS.saveData;                   % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.CLUSTERING.pathsFcn        = OPTIONS.pathsScript;                % 'string': Name of the paths script (normally leave as is)
OPTIONS.CLUSTERING.overwrite       = 'yes';                              % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Clustering summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.CLUSTERINGSUMMARY.inputName  = OPTIONS.CLUSTERING.outputName; % 'string': Saved per-subject clustering coefficient results to collect
OPTIONS.CLUSTERINGSUMMARY.outputName = 'clustering_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.CLUSTERINGSUMMARY.format     = 'both';                        % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.CLUSTERINGSUMMARY.pathsFcn   = OPTIONS.pathsScript;           % 'string': Name of the paths script (normally leave as is)

%% Path length options
% Path length: how many strong connections it takes on average to get from one
% channel to another (shorter = more efficient communication), with related
% measures such as global efficiency.
% Needs the Brain Connectivity Toolbox that comes with FieldTrip.
% See calculatePathlengthWs
OPTIONS.PATHLENGTH.inputName       = OPTIONS.PLICONNECTIVITY.outputName;                        % 'string': Saved PLI connectivity file the path length measures is calculated from
OPTIONS.PATHLENGTH.outputName      = 'PATHLENGTH';                                              % 'string': Name the path length measures results are saved under
OPTIONS.PATHLENGTH.conditions      = [129 139];                                                 % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.PATHLENGTH.conditionLabels = {'NonSocial', 'Social'};                                   % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.PATHLENGTH.measures        = {'L', 'efficiency', 'eccentricity', 'radius', 'diameter'}; % { cell }: Measures to report: 'L' (characteristic path length), 'efficiency' (global efficiency), 'eccentricity' (mean eccentricity), 'radius', 'diameter'
OPTIONS.PATHLENGTH.computeGlobal   = 'yes';                                                     % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.PATHLENGTH.computeROI      = 'yes';                                                     % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.PATHLENGTH.ROI             = ROI;                                                       % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.PATHLENGTH.edgeType        = 'weighted';                                                % 'string': 'weighted' = use the connection strengths (rescaled to 0-1); 'binary' = treat the network as unweighted (see the function help)
OPTIONS.PATHLENGTH.spctrmfield     = 'plispctrm';                                               % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.PATHLENGTH.saveData        = OPTIONS.saveData;                                          % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.PATHLENGTH.pathsFcn        = OPTIONS.pathsScript;                                       % 'string': Name of the paths script (normally leave as is)
OPTIONS.PATHLENGTH.overwrite       = 'yes';                                                     % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Path length summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.PATHLENGTHSUMMARY.inputName  = OPTIONS.PATHLENGTH.outputName; % 'string': Saved per-subject path length measures results to collect
OPTIONS.PATHLENGTHSUMMARY.outputName = 'pathlength_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.PATHLENGTHSUMMARY.format     = 'both';                        % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.PATHLENGTHSUMMARY.pathsFcn   = OPTIONS.pathsScript;           % 'string': Name of the paths script (normally leave as is)

%% Betweenness centrality options
% Betweenness centrality: how often a channel lies on the shortest paths
% between other channels (a measure of how much of a hub it is), averaged
% over channels.
% Needs the Brain Connectivity Toolbox that comes with FieldTrip.
% See calculateBetweennessCentrality
OPTIONS.BC.inputName       = OPTIONS.PLICONNECTIVITY.outputName; % 'string': Saved PLI connectivity file the betweenness centrality is calculated from
OPTIONS.BC.outputName      = 'BC';                               % 'string': Name the betweenness centrality results are saved under
OPTIONS.BC.conditions      = [129 139];                          % [ number ]: Trigger codes of the conditions to report separately; results over all epochs ('Global') are always added; [] = only global
OPTIONS.BC.conditionLabels = {'NonSocial', 'Social'};            % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.BC.computeGlobal   = 'yes';                              % 'string': Calculate for the whole network (all channels): 'yes' or 'no'
OPTIONS.BC.computeROI      = 'yes';                              % 'string': Calculate for each region of interest separately (small networks, interpret with caution): 'yes' or 'no'
OPTIONS.BC.ROI             = ROI;                                % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.BC.edgeType        = 'weighted';                         % 'string': 'weighted' = use the connection strengths (rescaled to 0-1); 'binary' = treat the network as unweighted (see the function help)
OPTIONS.BC.spctrmfield     = 'plispctrm';                        % 'string': Name of the connectivity data inside the PLI file (normally leave as is)
OPTIONS.BC.saveData        = OPTIONS.saveData;                   % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.BC.pathsFcn        = OPTIONS.pathsScript;                % 'string': Name of the paths script (normally leave as is)
OPTIONS.BC.overwrite       = 'yes';                              % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Betweenness centrality summary options
% Collects the results of all subjects in one file. See collectNetmetSummary
OPTIONS.BCSUMMARY.inputName  = OPTIONS.BC.outputName; % 'string': Saved per-subject betweenness centrality results to collect
OPTIONS.BCSUMMARY.outputName = 'bc_summary';          % 'string': Name of the summary file (no extension; saved in the summary folder, PATHS.SUMMARY)
OPTIONS.BCSUMMARY.format     = 'both';                % 'string': File type(s) to write: 'csv', 'mat' or 'both'
OPTIONS.BCSUMMARY.pathsFcn   = OPTIONS.pathsScript;   % 'string': Name of the paths script (normally leave as is)

%% Subject summary collection options
% Collects the information of all subjects in one file. See collectSubjectSummary
OPTIONS.SUBJECTSUMMARY.outputFile = 'SubjectSummary.csv'; % 'string': Name of the summary file with one row per subject (saved in the summary folder, PATHS.SUMMARY)
OPTIONS.SUBJECTSUMMARY.pathsFcn   = OPTIONS.pathsScript;  % 'string': Name of the paths script (normally leave as is)
