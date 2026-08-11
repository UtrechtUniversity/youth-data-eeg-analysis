%% Settings for Network Metrics
% Automatically copied as setOptions_netmet.m to each new
% analysis folder by bv_createNewAnalysis. Adjust settings
% before running networkMetrics.m.

% populates OPTIONS with the preprocessing settings
% (incl. required REREF)
setOptions;

%% General options
OPTIONS.saveData    = 'yes';
OPTIONS.pathsScript = 'setPaths';

%% PLI connectivity options
% Frequency bands for PLI connectivity (and therefore for every downstream
% network metric, which just reports one column per band already present
% in the PLI file). Fields are band labels, values are [low high] Hz
% ranges used to band-pass filter the continuous signal before PLI is
% computed for that band. Add/remove/rename bands here as needed - column
% order downstream follows fieldnames(freqBands), i.e. the order below.
freqBands = struct;
freqBands.delta       = [1 3];   % Hz
freqBands.theta       = [4 7];   % Hz
freqBands.alpha       = [8 12];  % Hz
freqBands.beta        = [13 25]; % Hz
freqBands.gamma       = [26 35]; % Hz
freqBands.infantTheta = [3 6];   % Hz
freqBands.infantAlpha = [6 9];   % Hz
freqBands.total       = [1 35];  % Hz

OPTIONS.PLICONNECTIVITY.inputName      = 'APPEND';   % clean-trial definitions (sampleinfo/trialinfo/condition)
OPTIONS.PLICONNECTIVITY.method         = 'pli';      % connectivity method
OPTIONS.PLICONNECTIVITY.freqOutput     = 'powandcsd';
OPTIONS.PLICONNECTIVITY.freqBands      = freqBands;
OPTIONS.PLICONNECTIVITY.triallength    = OPTIONS.triallength;
OPTIONS.PLICONNECTIVITY.outputName     = ['PLI' num2str(OPTIONS.triallength)];
OPTIONS.PLICONNECTIVITY.saveData       = OPTIONS.saveData;
OPTIONS.PLICONNECTIVITY.optionsFcn     = OPTIONS.pathsScript;
OPTIONS.PLICONNECTIVITY.keeptrials     = 'yes';         % keep per-epoch matrices
OPTIONS.PLICONNECTIVITY.preprocOptions = OPTIONS.REREF; % settings used to re-derive the continuous filtered signal

%% ROI definitions (shared by the ROI-based network metrics)
ROI = struct;
ROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
ROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
ROI.RightFrontal  = {'F4','F8','FC6','FC2'};
ROI.Central       = {'C3','C4','CP1','CP2','Cz'};
ROI.LeftParietal  = {'T7','CP5','P7','P3'};
ROI.RightParietal = {'T8','CP6','P8','P4'};
ROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

%% FC strength options
OPTIONS.STRENGTH.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.STRENGTH.outputName      = 'STRENGTH';
OPTIONS.STRENGTH.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.STRENGTH.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.STRENGTH.computeGlobal   = 'yes';       % whole-network strength
OPTIONS.STRENGTH.computeROI      = 'yes';       % per-ROI strength
OPTIONS.STRENGTH.ROI             = ROI;
OPTIONS.STRENGTH.spctrmfield     = 'plispctrm';
OPTIONS.STRENGTH.saveData        = OPTIONS.saveData;
OPTIONS.STRENGTH.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.STRENGTH.overwrite       = 'yes';

%% FC strength summary (cross-subject) options
OPTIONS.STRENGTHSUMMARY.inputName  = OPTIONS.STRENGTH.outputName;  % per-subject metric file
OPTIONS.STRENGTHSUMMARY.outputName = 'strength_summary';           % base filename in PATHS.SUMMARY
OPTIONS.STRENGTHSUMMARY.format     = 'both';                       % 'csv' | 'mat' | 'both'
OPTIONS.STRENGTHSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Small-world propensity options
% Uses MATLAB's built-in graph/distances functions; no toolbox required.
OPTIONS.SWP.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.SWP.outputName      = 'SWP';
OPTIONS.SWP.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.SWP.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.SWP.computeGlobal   = 'yes';       % whole-network SWP
OPTIONS.SWP.computeROI      = 'yes';       % per-ROI SWP (small subgraphs; interpret with caution)
OPTIONS.SWP.ROI             = ROI;
OPTIONS.SWP.spctrmfield     = 'plispctrm';
OPTIONS.SWP.saveData        = OPTIONS.saveData;
OPTIONS.SWP.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.SWP.overwrite       = 'yes';

%% SWP summary (cross-subject) options
OPTIONS.SWPSUMMARY.inputName  = OPTIONS.SWP.outputName;
OPTIONS.SWPSUMMARY.outputName = 'swp_summary';
OPTIONS.SWPSUMMARY.format     = 'both'; % 'csv' | 'mat' | 'both'
OPTIONS.SWPSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Q modularity options
% Requires FieldTrip's bundled Brain Connectivity Toolbox (community_louvain).
OPTIONS.QMOD.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.QMOD.outputName      = 'QMOD';
OPTIONS.QMOD.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.QMOD.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.QMOD.computeGlobal   = 'yes';       % whole-network modularity
OPTIONS.QMOD.computeROI      = 'yes';       % per-ROI modularity (small subgraphs; interpret with caution)
OPTIONS.QMOD.ROI             = ROI;
OPTIONS.QMOD.edgeType        = 'weighted';
OPTIONS.QMOD.gamma           = 1;
OPTIONS.QMOD.spctrmfield     = 'plispctrm';
OPTIONS.QMOD.saveData        = OPTIONS.saveData;
OPTIONS.QMOD.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.QMOD.overwrite       = 'yes';

%% Q modularity summary (cross-subject) options
OPTIONS.QMODSUMMARY.inputName  = OPTIONS.QMOD.outputName;
OPTIONS.QMODSUMMARY.outputName = 'qmod_summary';
OPTIONS.QMODSUMMARY.format     = 'both'; % 'csv' | 'mat' | 'both'
OPTIONS.QMODSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Clustering coefficient options
% Uses FieldTrip's bundled Brain Connectivity Toolbox (clustering_coef_bu/wu).
OPTIONS.CLUSTERING.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.CLUSTERING.outputName      = 'CLUSTERING';
OPTIONS.CLUSTERING.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.CLUSTERING.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.CLUSTERING.computeGlobal   = 'yes';       % whole-network clustering
OPTIONS.CLUSTERING.computeROI      = 'yes';       % per-ROI clustering (small subgraphs; interpret with caution)
OPTIONS.CLUSTERING.ROI             = ROI;
OPTIONS.CLUSTERING.edgeType        = 'weighted';
OPTIONS.CLUSTERING.spctrmfield     = 'plispctrm';
OPTIONS.CLUSTERING.saveData        = OPTIONS.saveData;
OPTIONS.CLUSTERING.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.CLUSTERING.overwrite       = 'yes';

%% Clustering summary (cross-subject) options
OPTIONS.CLUSTERINGSUMMARY.inputName  = OPTIONS.CLUSTERING.outputName;
OPTIONS.CLUSTERINGSUMMARY.outputName = 'clustering_summary';
OPTIONS.CLUSTERINGSUMMARY.format     = 'both'; % 'csv' | 'mat' | 'both'
OPTIONS.CLUSTERINGSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Path length options
% Uses FieldTrip's bundled Brain Connectivity Toolbox (distance_bin/wei, charpath).
OPTIONS.PATHLENGTH.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.PATHLENGTH.outputName      = 'PATHLENGTH';
OPTIONS.PATHLENGTH.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.PATHLENGTH.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.PATHLENGTH.measures        = {'L', 'efficiency', 'eccentricity', 'radius', 'diameter'};  % which charpath measures to compute
OPTIONS.PATHLENGTH.computeGlobal   = 'yes';       % whole-network path length
OPTIONS.PATHLENGTH.computeROI      = 'yes';       % per-ROI path length (small subgraphs; interpret with caution)
OPTIONS.PATHLENGTH.ROI             = ROI;
OPTIONS.PATHLENGTH.edgeType        = 'weighted';
OPTIONS.PATHLENGTH.spctrmfield     = 'plispctrm';
OPTIONS.PATHLENGTH.saveData        = OPTIONS.saveData;
OPTIONS.PATHLENGTH.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.PATHLENGTH.overwrite       = 'yes';

%% Path length summary (cross-subject) options
OPTIONS.PATHLENGTHSUMMARY.inputName  = OPTIONS.PATHLENGTH.outputName;
OPTIONS.PATHLENGTHSUMMARY.outputName = 'pathlength_summary';
OPTIONS.PATHLENGTHSUMMARY.format     = 'both'; % 'csv' | 'mat' | 'both'
OPTIONS.PATHLENGTHSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Betweenness centrality options
% Uses FieldTrip's bundled Brain Connectivity Toolbox (betweenness_bin/wei).
OPTIONS.BC.inputName       = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.BC.outputName      = 'BC';
OPTIONS.BC.conditions      = [129 139];   % processed separately; a pooled pass (always labelled 'Global') is always added
OPTIONS.BC.conditionLabels = {'NonSocial', 'Social'};  % positionally matched to conditions
OPTIONS.BC.computeGlobal   = 'yes';       % whole-network betweenness centrality
OPTIONS.BC.computeROI      = 'yes';       % per-ROI betweenness centrality (small subgraphs; interpret with caution)
OPTIONS.BC.ROI             = ROI;
OPTIONS.BC.edgeType        = 'weighted';
OPTIONS.BC.spctrmfield     = 'plispctrm';
OPTIONS.BC.saveData        = OPTIONS.saveData;
OPTIONS.BC.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.BC.overwrite       = 'yes';

%% Betweenness centrality summary (cross-subject) options
OPTIONS.BCSUMMARY.inputName  = OPTIONS.BC.outputName;
OPTIONS.BCSUMMARY.outputName = 'bc_summary';
OPTIONS.BCSUMMARY.format     = 'both'; % 'csv' | 'mat' | 'both'
OPTIONS.BCSUMMARY.pathsFcn   = OPTIONS.pathsScript;
