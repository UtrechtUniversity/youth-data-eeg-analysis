% Default options file for the YOUth EEG connectivity calculations. Even when
% using the default options, please go through all these options carefully
% to prevent errors. 


 %% General options
% general options for the whole experiment
OPTIONS.saveData                = 'yes'; % 'string': ('yes' or 'no') to determine whether data is saved 
OPTIONS.triallength             = 3; % [ number ]: triallength used for analysis 
OPTIONS.artifacttrllength       = 1;
OPTIONS.pathsScript             = 'setPaths'; % 'string': pathScript name ('setPaths') 
OPTIONS.sDirString              = 'B'; % 'string': unique search string for raw eeg files which will find all files when used as dir ( ['*' sDirString '*'] ) 
OPTIONS.dataType                = 'bdf'; % 'string': ('bdf' or 'eeg') to determine which datatype will be used for the analyses 
OPTIONS.maxbadchans             = 3;

%% Create subject folders
OPTIONS.CREATEFOLDERS.pathsFcn      = OPTIONS.pathsScript;
OPTIONS.CREATEFOLDERS.inputName     = []; % only required when datatype = 'mat'
OPTIONS.CREATEFOLDERS.rawdelim      = '_'; % delimiter found in raw eeg files
OPTIONS.CREATEFOLDERS.rawlabel      = {'pseudo', 'wave'}; % label the seperate elements of eeg file name (with delimiters in between)
OPTIONS.CREATEFOLDERS.sfoldername   = {'pseudo', 'wave'}; % how your subject folders should be labeled
OPTIONS.CREATEFOLDERS.overwrite     = 'yes';
OPTIONS.CREATEFOLDERS.sDirString    = OPTIONS.sDirString; % match string to find bdf files 
OPTIONS.CREATEFOLDERS.dataType      = 'bdf'; % data type (can be 'bdf, 'eeg', 'mat')

%% Preprocessing options
% options only used for the preprocessing of the data 
OPTIONS.PREPROC.resampleFs      = 512; % [ number ]: resampling frequency. 
OPTIONS.PREPROC.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': filename of trialfun to be used (please add trialfun to your path) 
OPTIONS.PREPROC.hpfreq          = 0.16; % [ number ]: high-pass filter frequency cut-off 
OPTIONS.PREPROC.lpfreq          = []; % [ number ]: low-pass filter frequency cut-off 
OPTIONS.PREPROC.notchfreq       = 50; % [ number ]: notch filter frequency 
OPTIONS.PREPROC.pathsFcn        = OPTIONS.pathsScript; 
OPTIONS.PREPROC.filttype        = []; % 'string': ('but' or 'firws'). If none given, 'but' is used. 
OPTIONS.PREPROC.saveData        = OPTIONS.saveData; 
OPTIONS.PREPROC.outputName      = 'PREPROC'; % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputName .mat] 
OPTIONS.PREPROC.rmChannels      = {}; % { cell }: names of channels to be removed before preprocessing 
OPTIONS.PREPROC.overwrite       = 1; % [ number ]: set to 1 to overwrite existing data 
OPTIONS.PREPROC.reref           = 'no'; % 'string': 'yes' to rereference data (default: 'no') 
OPTIONS.PREPROC.refelec         = ''; % rereference electrode (string / number / cell of strings) 
OPTIONS.PREPROC.overwrite       = 'yes';
OPTIONS.PREPROC.waveletThresh   = 'no';  
OPTIONS.PREPROC.removechans     = 'no';
OPTIONS.PREPROC.interpolate     = 'no';  

%% Calculate artifact values after preprocessing
OPTIONS.ARTFCTPREPROC.inputName       = 'PREPROC';
OPTIONS.ARTFCTPREPROC.outputName      = 'ARTFCTBEFORE';
OPTIONS.ARTFCTPREPROC.saveData        = 'yes';
OPTIONS.ARTFCTPREPROC.pathsFcn        = 'setPaths';
OPTIONS.ARTFCTPREPROC.cutintrials     = 'yes';
OPTIONS.ARTFCTPREPROC.triallength     = OPTIONS.artifacttrllength;
OPTIONS.ARTFCTPREPROC.overwrite       = 'yes';
OPTIONS.ARTFCTPREPROC.analyses        = {'kurtosis','variance', 'flatline', 'abs', 'jump'};

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
OPTIONS.RMCHANNELS.saveData        = 'yes';
OPTIONS.RMCHANNELS.maxpercbad      = 40;
OPTIONS.RMCHANNELS.expectedtrials  = 360./OPTIONS.artifacttrllength;
OPTIONS.RMCHANNELS.repairchans     = 'no';

%% Preprocessing + reref options without removed channels
% options only used for the preprocessing of the data 
OPTIONS.REREF.resampleFs      = 512; % [ number ]: resampling frequency. 
OPTIONS.REREF.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': filename of trialfun to be used (please add trialfun to your path) 
OPTIONS.REREF.hpfreq          = 0.16; % [ number ]: high-pass filter frequency cut-off 
OPTIONS.REREF.lpfreq          = []; % [ number ]: low-pass filter frequency cut-off 
OPTIONS.REREF.notchfreq       = 50; % [ number ]: notch filter frequency 
OPTIONS.REREF.pathsFcn        = OPTIONS.pathsScript; 
OPTIONS.REREF.saveData        = OPTIONS.saveData; 
OPTIONS.REREF.outputName      = 'PREPROCRMCHANNELS'; % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputName .mat] 
OPTIONS.REREF.overwrite       = 1; % [ number ]: set to 1 to overwrite existing data 
OPTIONS.REREF.reref           = 'yes'; % 'string': 'yes' to rereference data (default: 'no') 
OPTIONS.REREF.refelec         = 'all'; % rereference electrode (string / number / cell of strings) 
OPTIONS.REREF.removechans     = 'yes';
OPTIONS.REREF.waveletThresh   = 'no';  
OPTIONS.REREF.interpolate     = 'yes';  


%% Calculate artifact values after preprocessing
OPTIONS.ARTFCTRMCHANNELS.inputName       = 'PREPROCRMCHANNELS';
OPTIONS.ARTFCTRMCHANNELS.outputName      = 'ARTFCTRMCHANS';
OPTIONS.ARTFCTRMCHANNELS.saveData        = 'yes';
OPTIONS.ARTFCTRMCHANNELS.pathsFcn        = 'setPaths';
OPTIONS.ARTFCTRMCHANNELS.cutintrials     = 'yes';
OPTIONS.ARTFCTRMCHANNELS.triallength     = OPTIONS.artifacttrllength;
OPTIONS.ARTFCTRMCHANNELS.overwrite       = 'yes';


%% Data loss options
% set options for the removal of complete channels. It is recommended to 
% only remove channels that are flatlining of are extremely noisy, so much 
% so that they will influence the average rereference grossly. 
lims = struct;
lims.jump = 0;
lims.abs = 250;
lims.flatline = 0.1;
lims.kurtosis = 10;
lims.variance = 2000;

OPTIONS.CLEANED.lims            = lims;
OPTIONS.CLEANED.pathsFcn        = OPTIONS.pathsScript; 
OPTIONS.CLEANED.inputName       = 'PREPROCRMCHANNELS';
OPTIONS.CLEANED.outputName      = 'CLEANED';
OPTIONS.CLEANED.artfctdefStr    = 'ARTFCTRMCHANS';
OPTIONS.CLEANED.saveData        = 'yes';
OPTIONS.CLEANED.expectedtrials  = 360./OPTIONS.artifacttrllength;
OPTIONS.CLEANED.repairchans     = 'no';
OPTIONS.CLEANED.cleanDatafile   = 'yes';
OPTIONS.CLEANED.dataLossLabel   = 'dataLossAfter';
OPTIONS.CLEANED.cutIntoTrials   = 'yes';

%% Append
OPTIONS.APPENDED.pathsFcn        = OPTIONS.pathsScript; 
OPTIONS.APPENDED.inputName       = 'CLEANED';
OPTIONS.APPENDED.outputName      = 'APPEND';
OPTIONS.APPENDED.triallength     = OPTIONS.artifacttrllength;
OPTIONS.APPENDED.saveData        = 'yes';

%% PLI connetivity calculation options 
OPTIONS.PLICONNECTIVITY.inputName   = 'APPEND';% 'string': outputName of previous analysis step, to be used as input for this step 
OPTIONS.PLICONNECTIVITY.method      = 'pli'; % method used for calculating connectivity 
OPTIONS.PLICONNECTIVITY.freqOutput  = 'powandcsd'; % frequency output used 
OPTIONS.PLICONNECTIVITY.triallength = OPTIONS.triallength; % frequency output used 
OPTIONS.PLICONNECTIVITY.outputName  = ['PLI_', num2str(OPTIONS.triallength) ,'s']; %'string': addition to filename when saving, so that the output filename becomes [currSubject outputName .mat] 
OPTIONS.PLICONNECTIVITY.saveData    = OPTIONS.saveData; 
OPTIONS.PLICONNECTIVITY.optionsFcn  = OPTIONS.pathsScript;
OPTIONS.PLICONNECTIVITY.keeptrials  = 'yes';
