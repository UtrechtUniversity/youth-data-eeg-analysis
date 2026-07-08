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
