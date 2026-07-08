% Power analysis options template. Automatically copied as setOptionsPower.m
% to each new analysis folder by bv_createNewAnalysis. Adjust settings
% before running powerEstimates.m.

%% General options
OPTIONS.saveData    = 'yes';
OPTIONS.pathsScript = 'setPaths';

%% Frequency analysis options
OPTIONS.FREQUENCY.inputName   = 'APPEND';       % input step from preprocessing
OPTIONS.FREQUENCY.outputName  = 'FREQ';
OPTIONS.FREQUENCY.method      = 'mtmfft';
OPTIONS.FREQUENCY.taper       = 'hanning';
OPTIONS.FREQUENCY.foi         = 1:35;           % frequencies of interest (Hz)
OPTIONS.FREQUENCY.channel     = {'EEG'};
OPTIONS.FREQUENCY.keeptrials  = 'yes';          % keep per-trial spectra for condition splitting
OPTIONS.FREQUENCY.saveData    = OPTIONS.saveData;
OPTIONS.FREQUENCY.pathsFcn    = OPTIONS.pathsScript;
OPTIONS.FREQUENCY.overwrite   = 'yes';

%% ROI power extraction options
ROI = struct;
ROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
ROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
ROI.RightFrontal  = {'F4','F8','FC6','FC2'};
ROI.Central       = {'C3','C4','CP1','CP2','Cz'};
ROI.LeftParietal  = {'T7','CP5','P7','P3'};
ROI.RightParietal = {'T8','CP6','P8','P4'};
ROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

freqBands = struct;
freqBands.theta = [3 6];    % Hz
freqBands.alpha = [6 9];    % Hz
freqBands.total = [1 35];   % Hz, used as denominator for relative power

OPTIONS.ROIPOWER.inputName   = 'FREQ';
OPTIONS.ROIPOWER.outputName  = 'POWER';
OPTIONS.ROIPOWER.conditions  = [129 139];   % condition codes; set [] to pool all trials
OPTIONS.ROIPOWER.ROI         = ROI;
OPTIONS.ROIPOWER.freqBands   = freqBands;
OPTIONS.ROIPOWER.saveData    = OPTIONS.saveData;
OPTIONS.ROIPOWER.pathsFcn    = OPTIONS.pathsScript;
OPTIONS.ROIPOWER.overwrite   = 'yes';

%% Power summary collection options
OPTIONS.POWERSUMMARY.inputName  = 'POWER';
OPTIONS.POWERSUMMARY.outputFile = 'power_summary.csv';  % saved in PATHS.SUMMARY
OPTIONS.POWERSUMMARY.pathsFcn   = OPTIONS.pathsScript;
