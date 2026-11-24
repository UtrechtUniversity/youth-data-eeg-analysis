%% Settings for Power Estimation
% This file holds the settings of the power analysis. A copy is placed in
% every new analysis folder (as setOptionsPower.m). Adjust the values to the
% right of the '=' signs before running powerEstimates.m; the text after the
% '%' explains each setting.
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

%% General options
OPTIONS.saveData    = 'yes';      % 'string': Save the results of the steps in the subject folders: 'yes' or 'no' (stored in subjectdata)
OPTIONS.pathsScript = 'setPaths'; % 'string': Name of the paths script (normally leave as is)
OPTIONS.triallength = 3;          % [ number ]: Length (seconds) of the epochs the connectivity metric (PLI) is calculated on

%% Epoch preprocessed data into sliding windows for power estimation
% Cuts the clean data into epochs that overlap (sliding windows). The input
% is the joined clean data (APPEND), not CLEANED: CLEANED only holds separate
% 1 s segments, whereas APPEND joins consecutive clean segments into longer
% stretches, which are needed to cut epochs of 3s.
% See bv_redefineTriallength
OPTIONS.EPOCH.inputName    = 'APPEND';            % 'string': Saved result that is cut into epochs (the joined clean data)
OPTIONS.EPOCH.outputName   = 'EPOCHS';            % 'string': Name the epochs are saved under
OPTIONS.EPOCH.triallength  = OPTIONS.triallength; % [ number ]: Length of each epoch in seconds
OPTIONS.EPOCH.overlap      = 2/3;                 % [ number ]: Overlap between consecutive epochs as a fraction (0-1); 2/3 of 3 s epochs = a new epoch every 1 s
OPTIONS.EPOCH.saveData     = OPTIONS.saveData;    % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.EPOCH.pathsFcn     = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)
OPTIONS.EPOCH.overwrite    = 'yes';               % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Artefact detection on the epoched data
% Measures the artefacts in every epoch, with the same measures as in the
% preprocessing. See bv_createArtefactStruct
OPTIONS.ARTFCTEPOCH.inputName    = 'EPOCHS';                                   % 'string': Saved epochs the artefacts are calculated on
OPTIONS.ARTFCTEPOCH.outputName   = 'ARTFCTEPOCHS';                             % 'string': Name the artefact values are saved under
OPTIONS.ARTFCTEPOCH.saveData     = OPTIONS.saveData;                           % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.ARTFCTEPOCH.pathsFcn     = OPTIONS.pathsScript;                        % 'string': Name of the paths script (normally leave as is)
OPTIONS.ARTFCTEPOCH.cutintrials  = 'no';                                       % 'string': Cut the data into shorter segments first: 'yes' or 'no' ('no': the epochs already have the right length)
OPTIONS.ARTFCTEPOCH.triallength  = [];                                         % [ number ]: Segment length in seconds (only used if cutintrials = 'yes'); [] = not used
OPTIONS.ARTFCTEPOCH.overwrite    = 'yes';                                      % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.ARTFCTEPOCH.analyses     = {'kurtosis','variance', 'flatline', 'abs'}; % { cell }: Artefact measures: kurtosis, variance, flatline (flat signal), abs (largest absolute amplitude), or 'all'

%% Remove artefact-contaminated epochs
% Removes the epochs with artefacts: an epoch that exceeds any of the
% thresholds below is discarded. These thresholds are intentionally the same
% as in the clean-data step of setOptions.m (same rejection criteria, now
% applied to each 3 s epoch). We suggest to keep them in sync. The
% connectivity step (setOptionsNetmet.m) checks its epochs against the same
% limits.
%
% Two optional settings below: cleanEpochs = 'no' keeps every epoch (the
% artefact values of the step above are still calculated and saved), and
% minEpochs removes a subject that has fewer clean epochs than that number.
epochLims = struct;
epochLims.abs      = 250;   % [ number ]: largest allowed absolute amplitude (uV)
epochLims.flatline = 0.1;   % [ number ]: flat-signal measure (1 ./ SD.^2); higher = flatter
epochLims.kurtosis = 10;    % [ number ]: peakedness of the signal distribution
epochLims.variance = 2000;  % [ number ]: variance of the signal (uV^2)

% See bv_cleanData
OPTIONS.CLEANEPOCHS.pathsFcn       = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)
OPTIONS.CLEANEPOCHS.inputName      = 'EPOCHS';            % 'string': Saved epochs the bad ones are removed from
OPTIONS.CLEANEPOCHS.artefactData   = 'ARTFCTEPOCHS';      % 'string': Saved artefact values to use (from the artefact step above)
OPTIONS.CLEANEPOCHS.outputName     = 'CLEANEPOCHS';       % 'string': Name the clean epochs are saved under
OPTIONS.CLEANEPOCHS.saveData       = OPTIONS.saveData;    % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.CLEANEPOCHS.cleanEpochs    = 'yes';               % 'string': Remove the noisy epochs, those with an artefact measure above a limit below: 'yes' or 'no' ('no' keeps every epoch and the limits are not used)
OPTIONS.CLEANEPOCHS.lims           = epochLims;           % struct: Thresholds above which an epoch is discarded (see above)
OPTIONS.CLEANEPOCHS.minEpochs      = [];                  % [ number ]: Minimum number of clean epochs a subject needs; a subject with fewer is removed. [] = no minimum (a subject is then only removed when no clean epoch is left)
OPTIONS.CLEANEPOCHS.stage          = 'power';             % 'string': Pipeline stage of this cleaning, so its epoch counts are stored separately from those of the preprocessing stage (normally leave as is)
OPTIONS.CLEANEPOCHS.saveCleanData  = 'yes';               % 'string': 'yes' = skip subjects that already have a result (unless overwrite = 'yes')
OPTIONS.CLEANEPOCHS.overwrite      = 'no';                % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.CLEANEPOCHS.calculateDataloss = 'no';             % 'string': Calculate the percentage of epochs lost by the cleaning and store it for the subject: 'yes' or 'no'
OPTIONS.CLEANEPOCHS.dataLossLabel  = 'dataLoss';          % 'string': Name under which that percentage is stored (only if calculateDataloss = 'yes')
OPTIONS.CLEANEPOCHS.expectedtrials = [];                  % [ number ]: Number of epochs expected per subject (only needed if calculateDataloss = 'yes'); [] = not used

%% Frequency analysis options
% Calculates the power spectrum of every clean epoch. See bv_calculateFrequency
OPTIONS.FREQUENCY.inputName   = 'CLEANEPOCHS';       % 'string': Saved clean epochs the power spectra are calculated on
OPTIONS.FREQUENCY.outputName  = 'FREQ';              % 'string': Name the spectra are saved under
OPTIONS.FREQUENCY.method      = 'mtmfft';            % 'string': Spectral method: 'mtmfft' = multitaper Fourier transform (see ft_freqanalysis)
OPTIONS.FREQUENCY.taper       = 'hanning';           % 'string': Window applied to each epoch before the Fourier transform (see ft_freqanalysis)
OPTIONS.FREQUENCY.foi         = 1:35;                % [ number ]: Frequencies (Hz) to calculate power for; 1:35 = every 1 Hz from 1 to 35 Hz (see ft_freqanalysis)
OPTIONS.FREQUENCY.channel     = {'EEG'};             % { cell }: Channels to include; {'EEG'} = all EEG channels (see ft_freqanalysis)
OPTIONS.FREQUENCY.keeptrials  = 'yes';               % 'string': Keep the spectrum of every epoch (needed to split by condition): 'yes' or 'no' (see ft_freqanalysis)
OPTIONS.FREQUENCY.saveData    = OPTIONS.saveData;    % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.FREQUENCY.pathsFcn    = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)
OPTIONS.FREQUENCY.overwrite   = 'yes';               % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% ROI power extraction options
% Calculates the power per frequency band in regions of interest (ROIs),
% for every epoch, every condition and over all epochs. See bv_extractROIPower
% Regions of interest: each name is followed by the channels it consists of
ROI = struct;
ROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
ROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
ROI.RightFrontal  = {'F4','F8','FC6','FC2'};
ROI.Central       = {'C3','C4','CP1','CP2','Cz'};
ROI.LeftParietal  = {'T7','CP5','P7','P3'};
ROI.RightParietal = {'T8','CP6','P8','P4'};
ROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

% Frequency bands for the power estimates, as [lowest highest] in Hz.
% The lowest frequency is included in the band, the highest is exlcuded.
freqBands = struct;
freqBands.delta       = [1 3];   % Hz
freqBands.theta       = [4 7];   % Hz
freqBands.alpha       = [8 12];  % Hz
freqBands.beta        = [13 25]; % Hz
freqBands.gamma       = [26 35]; % Hz
freqBands.infantTheta = [3 6];   % Hz
freqBands.infantAlpha = [6 9];   % Hz
freqBands.total       = [1 35];  % Hz, the denominator for relative power

OPTIONS.ROIPOWER.inputName       = 'FREQ';                  % 'string': Saved spectra the power is taken from
OPTIONS.ROIPOWER.outputName      = 'POWER';                 % 'string': Name the power values are saved under
OPTIONS.ROIPOWER.conditions      = [129 139];               % [ number ]: Trigger codes of the conditions to report separately; [] = no split by condition
OPTIONS.ROIPOWER.conditionLabels = {'NonSocial', 'Social'}; % { cell }: Names for the conditions, in the same order as the codes above
OPTIONS.ROIPOWER.ROI             = ROI;                     % struct: Regions of interest: name and channels of each (defined above)
OPTIONS.ROIPOWER.freqBands       = freqBands;               % struct: Frequency bands in Hz (defined above); 'total' is the denominator of relative power
OPTIONS.ROIPOWER.calcMethod      = 'raw';                   % 'string': Store power as raw values ('raw') or as log10 of the values ('log10')
OPTIONS.ROIPOWER.saveData        = OPTIONS.saveData;        % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.ROIPOWER.pathsFcn        = OPTIONS.pathsScript;     % 'string': Name of the paths script (normally leave as is)
OPTIONS.ROIPOWER.overwrite       = 'yes';                   % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Power summary collection options
% Collects the power of all subjects in one file. See bv_collectPowerSummary
OPTIONS.POWERSUMMARY.inputName  = 'POWER';             % 'string': Saved per-subject power result to collect
OPTIONS.POWERSUMMARY.outputFile = 'power_summary.csv'; % 'string': Name of the summary file with the power of all subjects (saved in the summary folder, PATHS.SUMMARY)
OPTIONS.POWERSUMMARY.pathsFcn   = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)

%% Subject summary collection options
% Collects the information of all subjects in one file. See bv_collectSubjectSummary
OPTIONS.SUBJECTSUMMARY.outputFile = 'SubjectSummary.csv'; % 'string': Name of the summary file with one row per subject (saved in the summary folder, PATHS.SUMMARY)
OPTIONS.SUBJECTSUMMARY.pathsFcn   = OPTIONS.pathsScript;  % 'string': Name of the paths script (normally leave as is)
