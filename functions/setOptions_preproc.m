%% Settings for Preprocessing
% This file is automatically added to your Analysis directory
% to keep track of all the settings set when the analysis
% was last ran.

%% General options
% general options for the whole experiment
OPTIONS.saveData                = 'yes'; % 'string': ('yes' or 'no') to determine whether data is saved
OPTIONS.triallength             = 3; % [ number ]: triallength used for analysis
OPTIONS.artifacttrllength       = 1;
OPTIONS.pathsScript             = 'setPaths'; % 'string': pathScript name ('setPaths')
OPTIONS.trigger.value           = []; % [ double ]: trigger value(s)
OPTIONS.trigger.label           = {}; % { cell }: trigger label(s) (e.g. 'Social' vs 'NonSocial'). Must be equal in length with trigger value.
OPTIONS.maxbadchans             = 3;

%% Create subject folders
OPTIONS.CREATEFOLDERS.pathsFcn      = OPTIONS.pathsScript;
OPTIONS.CREATEFOLDERS.prevAnalysis  = []; % only required when datatype = 'mat'
OPTIONS.CREATEFOLDERS.rawdelim      = '_'; % delimiter found in raw eeg files
OPTIONS.CREATEFOLDERS.sfoldername   = {'pseudo', 'wave'}; % how your subject folders should be labeled
OPTIONS.CREATEFOLDERS.overwrite     = 'yes';
OPTIONS.CREATEFOLDERS.dataType      = 'bdf'; % data type (can be 'bdf, 'eeg', 'mat')

OPTIONS.CREATEFOLDERS.rawlabel      = {'pseudo', 'wave'}; % label the seperate elements of eeg file name (with delimiters in between)
OPTIONS.CREATEFOLDERS.folderlabel   = {'wave', 'pseudo'};
OPTIONS.CREATEFOLDERS.folderPattern = {'', 'B'};
OPTIONS.CREATEFOLDERS.filePattern   = '';

%% Preprocessing options
% options only used for the preprocessing of the data
OPTIONS.PREPROC.resampleFs      = 512; % [ number ]: resampling frequency.
OPTIONS.PREPROC.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': filename of trialfun to be used (please add trialfun to your path)
OPTIONS.PREPROC.hpfreq          = 0.16; % [ number ]: high-pass filter frequency cut-off
OPTIONS.PREPROC.lpfreq          = 70; % [ number ]: low-pass filter frequency cut-off
OPTIONS.PREPROC.notchfreq       = 50; % [ number ]: notch filter frequency
OPTIONS.PREPROC.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.PREPROC.filttype        = []; % 'string': ('but' or 'firws'). If none given, 'but' is used.
OPTIONS.PREPROC.saveData        = OPTIONS.saveData;
OPTIONS.PREPROC.outputName       = 'PREPROC'; % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputName .mat]
OPTIONS.PREPROC.rmChannels      = {}; % { cell }: names of channels to be removed before preprocessing
OPTIONS.PREPROC.overwrite       = 1; % [ number ]: set to 1 to overwrite existing data
OPTIONS.PREPROC.reref           = 'no'; % 'string': 'yes' to rereference data (default: 'no')
OPTIONS.PREPROC.refelec         = ''; % rereference electrode (string / number / cell of strings)
OPTIONS.PREPROC.overwrite       = 'yes';
OPTIONS.PREPROC.channels        = {'EEG'};

%% Calculate artifact values after preprocessing
OPTIONS.ARTFCTPREPROC.inputName       = 'PREPROC';
OPTIONS.ARTFCTPREPROC.outputName      = 'ARTFCTBEFORE';
OPTIONS.ARTFCTPREPROC.saveData        = OPTIONS.saveData;
OPTIONS.ARTFCTPREPROC.pathsFcn        = 'setPaths';
OPTIONS.ARTFCTPREPROC.cutintrials     = 'yes';
OPTIONS.ARTFCTPREPROC.triallength     = OPTIONS.artifacttrllength;
OPTIONS.ARTFCTPREPROC.overwrite       = 'yes';
OPTIONS.ARTFCTPREPROC.analyses        = {'kurtosis','variance', 'flatline', 'abs'};

%% Remove channels options
% set options for the removal of complete channels. It is recommended to
% only remove channels that are flatlining of are extremely noisy, so much
% so that they will influence the average rereference grossly.
lims = struct;
lims.abs = 250; % uV
lims.flatline = 0.1; %1./std.^2
lims.kurtosis = 10;
lims.variance = 2000; % std.^2

OPTIONS.RMCHANNELS.lims            = lims;
OPTIONS.RMCHANNELS.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.RMCHANNELS.inputName       = 'PREPROC';
OPTIONS.RMCHANNELS.outputName      = 'PREPROCRMCHANNELS';
OPTIONS.RMCHANNELS.artefactData    = 'ARTFCTBEFORE';
OPTIONS.RMCHANNELS.saveData        = OPTIONS.saveData;
OPTIONS.RMCHANNELS.maxbadchans     = OPTIONS.maxbadchans;
OPTIONS.RMCHANNELS.maxpercbad      = 40;
OPTIONS.RMCHANNELS.expectedtrials  = 360./OPTIONS.artifacttrllength;
OPTIONS.RMCHANNELS.repairchans     = 'no';

%% Preprocessing + reref options without removed channels
% options only used for the preprocessing of the data
OPTIONS.REREF.resampleFs      = 512; % [ number ]: resampling frequency.
OPTIONS.REREF.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': filename of trialfun to be used (please add trialfun to your path)
OPTIONS.REREF.hpfreq          = 0.16; % [ number ]: high-pass filter frequency cut-off
OPTIONS.REREF.lpfreq          = 70; % [ number ]: low-pass filter frequency cut-off
OPTIONS.REREF.notchfreq       = 50; % [ number ]: notch filter frequency
OPTIONS.REREF.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.REREF.saveData        = OPTIONS.saveData;
OPTIONS.REREF.outputName      = 'PREPROCRMCHANNELS'; % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputName .mat]
OPTIONS.REREF.overwrite       = 1; % [ number ]: set to 1 to overwrite existing data
OPTIONS.REREF.channels        = {'EEG'};
OPTIONS.REREF.reref           = 'yes'; % 'string': 'yes' to rereference data (default: 'no')
OPTIONS.REREF.refelec         = 'all'; % rereference electrode (string / number / cell of strings)
OPTIONS.REREF.removechans     = 'yes';
OPTIONS.REREF.waveletThresh   = 'no';
OPTIONS.REREF.interpolate     = 'yes';
OPTIONS.REREF.interpMethod    = 'average';

%% Calculate artifact values after preprocessing
OPTIONS.ARTFCTRMCHANNELS.inputName       = 'PREPROCRMCHANNELS';
OPTIONS.ARTFCTRMCHANNELS.outputName      = 'ARTFCTRMCHANS';
OPTIONS.ARTFCTRMCHANNELS.saveData        = OPTIONS.saveData;
OPTIONS.ARTFCTRMCHANNELS.pathsFcn        = 'setPaths';
OPTIONS.ARTFCTRMCHANNELS.cutintrials     = 'yes';
OPTIONS.ARTFCTRMCHANNELS.triallength     = OPTIONS.artifacttrllength;
OPTIONS.ARTFCTRMCHANNELS.overwrite       = 'yes';
OPTIONS.ARTFCTRMCHANNELS.analyses        = {'kurtosis','variance', 'flatline', 'abs'};

%% Data loss options
% set options for the removal of complete channels. It is recommended to
% only remove channels that are flatlining of are extremely noisy, so much
% so that they will influence the average rereference grossly.
lims = struct;
lims.abs = 250;
lims.flatline = 0.1;
lims.kurtosis = 10;
lims.variance = 2000;

OPTIONS.CLEANED.lims            = lims;
OPTIONS.CLEANED.pathsFcn        = OPTIONS.pathsScript;
OPTIONS.CLEANED.inputName       = 'PREPROCRMCHANNELS';
OPTIONS.CLEANED.outputName      = 'CLEANED';
OPTIONS.CLEANED.artefactData    = 'ARTFCTRMCHANS';
OPTIONS.CLEANED.saveData        = OPTIONS.saveData;
OPTIONS.CLEANED.saveCleanData   = 'yes';
OPTIONS.CLEANED.expectedtrials  = 360./OPTIONS.artifacttrllength;
OPTIONS.CLEANED.repairchans     = 'no';
OPTIONS.CLEANED.cleanDatafile   = 'yes';
OPTIONS.CLEANED.dataLossLabel   = 'dataLossAfter';
OPTIONS.CLEANED.cutIntoTrials   = 'yes';

%% Append
OPTIONS.APPENDED.pathsFcn     = OPTIONS.pathsScript;
OPTIONS.APPENDED.inputName    = 'CLEANED';
OPTIONS.APPENDED.outputName   = 'APPEND';
OPTIONS.APPENDED.triallength  = OPTIONS.artifacttrllength;
OPTIONS.APPENDED.saveData     = OPTIONS.saveData;
