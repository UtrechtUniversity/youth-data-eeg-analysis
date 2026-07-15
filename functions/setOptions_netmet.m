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
OPTIONS.PLICONNECTIVITY.inputName      = 'APPEND';   % clean-trial definitions (sampleinfo/trialinfo/condition)
OPTIONS.PLICONNECTIVITY.method         = 'pli';      % connectivity method
OPTIONS.PLICONNECTIVITY.freqOutput     = 'powandcsd';
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
OPTIONS.STRENGTH.inputName     = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.STRENGTH.outputName    = 'STRENGTH';
OPTIONS.STRENGTH.conditions    = [129 139];   % processed separately; a pooled pass (label 0) is always added
OPTIONS.STRENGTH.computeGlobal = 'yes';       % whole-network strength
OPTIONS.STRENGTH.computeROI    = 'yes';       % per-ROI strength
OPTIONS.STRENGTH.ROI           = ROI;
OPTIONS.STRENGTH.spctrmfield   = 'plispctrm';
OPTIONS.STRENGTH.saveData      = OPTIONS.saveData;
OPTIONS.STRENGTH.pathsFcn      = OPTIONS.pathsScript;
OPTIONS.STRENGTH.overwrite     = 'yes';

%% FC strength summary (cross-subject) options
OPTIONS.STRENGTHSUMMARY.inputName  = OPTIONS.STRENGTH.outputName;  % per-subject metric file
OPTIONS.STRENGTHSUMMARY.outputName = 'strength_summary';          % base filename in PATHS.SUMMARY
OPTIONS.STRENGTHSUMMARY.format     = 'both';                      % 'csv' | 'mat' | 'both'
OPTIONS.STRENGTHSUMMARY.pathsFcn   = OPTIONS.pathsScript;

%% Small-world propensity options
% Requires the Bioinformatics Toolbox (graphallshortestpaths).
OPTIONS.SWP.inputName     = OPTIONS.PLICONNECTIVITY.outputName;  % PLI connectivity file
OPTIONS.SWP.outputName    = 'SWP';
OPTIONS.SWP.conditions    = [129 139];   % processed separately; a pooled pass (label 0) is always added
OPTIONS.SWP.computeGlobal = 'yes';       % whole-network SWP
OPTIONS.SWP.computeROI    = 'yes';       % per-ROI SWP (small subgraphs; interpret with caution)
OPTIONS.SWP.ROI           = ROI;
OPTIONS.SWP.spctrmfield   = 'plispctrm';
OPTIONS.SWP.saveData      = OPTIONS.saveData;
OPTIONS.SWP.pathsFcn      = OPTIONS.pathsScript;
OPTIONS.SWP.overwrite     = 'yes';

%% SWP summary (cross-subject) options
OPTIONS.SWPSUMMARY.inputName  = OPTIONS.SWP.outputName;
OPTIONS.SWPSUMMARY.outputName = 'swp_summary';
OPTIONS.SWPSUMMARY.format     = 'both';
OPTIONS.SWPSUMMARY.pathsFcn   = OPTIONS.pathsScript;
