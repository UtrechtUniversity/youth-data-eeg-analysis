% Power analysis options template. Automatically copied as setOptionsPower.m
% to each new analysis folder by bv_createNewAnalysis. Adjust settings
% before running powerEstimates.m.

%% General options
OPTIONS.saveData    = 'yes';
OPTIONS.pathsScript = 'setPaths';

%% Epoch preprocessed data into sliding windows for power estimation
% NOTE: input is APPEND, not CLEANED. CLEANED trials are only
% OPTIONS.artifacttrllength (1s) long each - bv_cleanData rebuilds trials
% directly from the artefact struct's per-second sampleinfo, it doesn't
% keep the original (up to posttrig-length) trialfun epochs. APPEND
% re-stitches consecutive clean 1s fragments back into longer continuous
% runs, which is what this sliding-window step actually needs as input.
OPTIONS.EPOCH.inputName    = 'APPEND';
OPTIONS.EPOCH.outputName   = 'EPOCHS';
OPTIONS.EPOCH.triallength  = 3;            % epoch length in seconds
OPTIONS.EPOCH.overlap      = 2/3;          % fraction overlap -> 1s step
OPTIONS.EPOCH.saveData     = OPTIONS.saveData;
OPTIONS.EPOCH.pathsFcn     = OPTIONS.pathsScript;
OPTIONS.EPOCH.overwrite    = 'yes';

%% Artefact detection on the epoched data
% Uses the same metrics as the preprocessing artefact steps
OPTIONS.ARTFCTEPOCH.inputName    = 'EPOCHS';
OPTIONS.ARTFCTEPOCH.outputName   = 'ARTFCTEPOCHS';
OPTIONS.ARTFCTEPOCH.saveData     = OPTIONS.saveData;
OPTIONS.ARTFCTEPOCH.pathsFcn     = OPTIONS.pathsScript;
OPTIONS.ARTFCTEPOCH.cutintrials  = 'no';   % epochs are already at target length
OPTIONS.ARTFCTEPOCH.overwrite    = 'yes';
OPTIONS.ARTFCTEPOCH.analyses     = {'kurtosis','variance', 'flatline', 'abs'};

%% Remove artefact-contaminated epochs
% NOTE: these limits are intentionally the same as lims in setOptions.m's
% ARTFCTRMCHANNELS/CLEANED steps (same rejection criteria, now reapplied
% per 3s epoch instead of per preprocessing trial). Keep them in sync.
epochLims = struct;
epochLims.abs      = 250;   % uV
epochLims.flatline = 0.1;   % 1./std.^2
epochLims.kurtosis = 10;
epochLims.variance = 2000;  % std.^2

OPTIONS.CLEANEPOCHS.lims           = epochLims;
OPTIONS.CLEANEPOCHS.pathsFcn       = OPTIONS.pathsScript;
OPTIONS.CLEANEPOCHS.inputName      = 'EPOCHS';
OPTIONS.CLEANEPOCHS.artefactData   = 'ARTFCTEPOCHS';
OPTIONS.CLEANEPOCHS.outputName     = 'CLEANEPOCHS';
OPTIONS.CLEANEPOCHS.saveData       = OPTIONS.saveData;
OPTIONS.CLEANEPOCHS.saveCleanData  = 'yes';
OPTIONS.CLEANEPOCHS.repairchans    = 'no';

%% Frequency analysis options
OPTIONS.FREQUENCY.inputName   = 'CLEANEPOCHS';  % input step from power epoching/rejection
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

% Frequency bands for power estimates
% ranges in Hz, lower-inlcusive and upper-exclusive
freqBands = struct;
freqBands.delta       = [1 3];   % Hz
freqBands.theta       = [4 7];   % Hz
freqBands.alpha       = [8 12];  % Hz
freqBands.beta        = [13 25]; % Hz
freqBands.gamma       = [26 35]; % Hz
freqBands.infantTheta = [3 6];   % Hz
freqBands.infantAlpha = [6 9];   % Hz
freqBands.total       = [1 35];  % Hz, used as denominator for relative power

OPTIONS.ROIPOWER.inputName       = 'FREQ';
OPTIONS.ROIPOWER.outputName      = 'POWER';
OPTIONS.ROIPOWER.conditions      = [129 139];   % condition codes; set [] to skip the per-condition breakdown
OPTIONS.ROIPOWER.conditionLabels = {'NonSocial', 'Social'};
OPTIONS.ROIPOWER.ROI             = ROI;
OPTIONS.ROIPOWER.freqBands       = freqBands;
OPTIONS.ROIPOWER.calcMethod      = 'raw';       % 'raw' or 'log10' for which to calculate and save
OPTIONS.ROIPOWER.saveData        = OPTIONS.saveData;
OPTIONS.ROIPOWER.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.ROIPOWER.overwrite       = 'yes';

%% Power summary collection options
OPTIONS.POWERSUMMARY.inputName  = 'POWER';
OPTIONS.POWERSUMMARY.outputFile = 'power_summary.csv';  % saved in PATHS.SUMMARY
OPTIONS.POWERSUMMARY.pathsFcn   = OPTIONS.pathsScript;
