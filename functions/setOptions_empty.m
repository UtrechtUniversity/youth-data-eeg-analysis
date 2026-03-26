% Empty options m-file for the analysis pipe line of baby connectivity
% data. This file should be added to your ROOT folder to keep track of all the
% settings set when the analysis was last ran. 


%% General options
% general options for the whole experiment
OPTIONS.saveData                = % 'string': ('yes' or 'no') to determine whether data is saved
OPTIONS.triallength             = % [ number ]: triallength used for analysis 
OPTIONS.pathsScript             = % 'string': pathScript name ('setPaths')
OPTIONS.sDirString              = % 'string': unique search string for raw eeg files which will find all files when used as dir ( ['*' sDirString '*'] )
OPTIONS.dataType                = % 'string': ('bdf' or 'eeg') to determine which datatype will be used for the analyses
OPTIONS.trigger.value           = % [ double ]: trigger value(s)
OPTIONS.trigger.label           = % { cell }: trigger label(s) (e.g. 'Social' vs 'NonSocial'). Must be equal in length with trigger value.

%% Preprocessing options
% options only used for the preprocessing of the data
OPTIONS.PREPROC.resampleFs      = % [ number ]: resampling frequency. 
OPTIONS.PREPROC.trialfun        = % 'string': filename of trialfun to be used (please add trialfun to your path)
OPTIONS.PREPROC.hpfreq          = % [ number ]: high-pass filter frequency cut-off
OPTIONS.PREPROC.lpfreq          = % [ number ]: low-pass filter frequency cut-off
OPTIONS.PREPROC.notchfreq       = % [ number ]: notch filter frequency 
OPTIONS.PREPROC.pathsFcn        = OPTIONS.pathsScript; 
OPTIONS.PREPROC.filttype        = % 'string': ('but' or 'firws'). If none given, 'but' is used.
OPTIONS.PREPROC.saveData        = OPTIONS.saveData;
OPTIONS.PREPROC.outputStr       = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.PREPROC.rmChannels      = % { cell }: names of channels to be removed before preprocessing 
OPTIONS.PREPROC.overwrite       = % [ number ]: set to 1 to overwrite existing data
OPTIONS.PREPROC.reref           = % 'string': 'yes' to rereference data (default: 'no')
OPTIONS.PREPROC.refelec         = % rereference electrode (string / number / cell of strings)

%% Independent component analysis options
% set options for component analysis. Recommended is the extended 'runica' 
% method
OPTIONS.COMP.saveData           = OPTIONS.saveData;
OPTIONS.COMP.outputStr          = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.COMP.inputStr           = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.COMP.method             = % 'string': (e.g. 'runica', 'fastica', check FT_COMPONENTANALYSIS for more options)
OPTIONS.COMP.extended           = % [ boolean ]: (1 or 0) to set whether 'runica' needs to be extended (recommended)
OPTIONS.COMP.optionsFcn         = OPTIONS.pathsScript;

%% Remove components options
% set options for the removal of components. Blink removal can be
% automatic. Works in 80-90 percent of the cases. Only if blinks are
% limited (like in young infants), the automatic script seems to fail.
% Steps are built-in to check removed component before removal. Please do
% not skip this step and ensure the correct components have been removed
OPTIONS.COMPREMOVED.saveData            = OPTIONS.saveData;
OPTIONS.COMPREMOVED.outputStr           = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.COMPREMOVED.compStr             = % 'string': outputstr of component analysis step, to be used to remove components
OPTIONS.COMPREMOVED.dataStr             = % 'string': outputstr of data analysis step from which components need to be removed
OPTIONS.COMPREMOVED.optionsFcn          = OPTIONS.pathsScript;
OPTIONS.COMPREMOVED.automaticRemoval    = % 'string': ('yes' or 'no'), to set whether automatic blink component removal is warranted 
OPTIONS.COMPREMOVED.blinkremoval        = % 'string': ('yes' or 'no'), to automatically remove blink components (only set when automaticRemoval is set to 'yes'). (default: 'no')
OPTIONS.COMPREMOVED.gammaremoval        = % 'string': ('yes' or 'no'), to automatically remove gamma components (only set when automaticRemoval is set to 'yes'). (default: 'no')
OPTIONS.COMPREMOVED.saveFigure          = % 'string': ('yes' or 'no'), to save component removal figure

%% Remove channels options
% set options for the removal of complete channels. It is recommended to
% only remove channels that are flatlining of are extremely noisy, so much
% so that they will influence the average rereference grossly. 
OPTIONS.RMCHANNELS.betaLim      = % [ number ]: Checks for trials very high in beta. Limit of the amount of beta-power accepted in a trial (in dB.). 
OPTIONS.RMCHANNELS.gammaLim     = % [ number ]: Checks for trials very high in gamma. Limit of the amount of gamma-power accepted in a trial (in dB.). 
OPTIONS.RMCHANNELS.varLim       = % [ number ]: Checks for highly varying trials. Limit of the amount of variance accepted in a trial 
OPTIONS.RMCHANNELS.flatLim      = % [ number ]: Checks for flatlining. Limit of the amount of inverse variance accepted in a trial 
OPTIONS.RMCHANNELS.kurtLim      = % [ number ]: Checks for jumps. Limit of the kurtosis per trial
OPTIONS.RMCHANNELS.vMaxLim      = % [ number ]: Checks for high amplitudes. Limit the max amplitude of a trial
OPTIONS.RMCHANNELS.triallength  = % [ number ]: Triallength used for artifact removal (usually set to 1s). The definitive triallength is set later in the analysis
OPTIONS.RMCHANNELS.cutOutputData= 'no'; % 'string': ('yes' or 'no') set to 'yes' if artefacts need to be recalculated after channel removal. Set to 'no' when doing the rmchannels, but 'yes' during trialremoval. **Terrible explanation, terrible variable name, just set it to 'no' if you want to remove channels. Will be changed**
OPTIONS.RMCHANNELS.showFigures  = % 'string': ('yes' or 'no'). 
OPTIONS.RMCHANNELS.saveFigures  = % 'string': ('yes' or 'no'). Can only save figures if figures are showed
OPTIONS.RMCHANNELS.inputStr     = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.RMCHANNELS.outputStr    = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.RMCHANNELS.saveData     = OPTIONS.saveData;
OPTIONS.RMCHANNELS.rmTrials     = 'no'; % 'string' ('yes' or 'no'), set to 'no' if no trials need to be removed
OPTIONS.RMCHANNELS.optionsFcn   = OPTIONS.pathsScript;
OPTIONS.RMCHANNELS.redefineTrial= % 'string': ('yes' or 'no'). Set to redefine data to given triallength. Do not set to yes if data is already cut in trials


%% Rereferencing options
OPTIONS.REREF.refElectrode      = % 'string': rereference electrode ('all' is average rereference)
OPTIONS.REREF.saveData          = OPTIONS.saveData;
OPTIONS.REREF.inputStr          = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.REREF.outputStr         = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.REREF.optionsFcn        = OPTIONS.pathsScript;


%% Cleaning options
OPTIONS.CLEANED.betaLim         = % [ number ]: Checks for trials high in beta power. Limit of the amount of beta-power accepted in a trial (in dB.). 
OPTIONS.CLEANED.gammaLim        = % [ number ]: Checks for trials high in gamma power. Limit of the amount of gamma-power accepted in a trial (in dB.). 
OPTIONS.CLEANED.varLim          = % [ number ]: Checks for trials with a high variance. Limit of the amount of variance accepted in a trial (uses var function of matlab)
OPTIONS.CLEANED.flatLim         = % [ number ]: Checks for flatlining. Limit of the amount of inverse variance accepted in a trial (uses var function of matlab)
OPTIONS.CLEANED.kurtLim         = % [ number ]: Checks for abnormal peakyness in epoch. Also useful to detect large jumps. Limit of the kurtosis per trial (uses kurtosis function of matlab)
OPTIONS.CLEANED.vMaxLim         = % [ number ]: Checks for high amplitudes. Limit the max amplitude of a trial
OPTIONS.CLEANED.triallength     = % [ number ]: Triallength (in seconds) used for artifact removal (usually set to 1). The definitive triallength is set later in the analysis
OPTIONS.CLEANED.cutOutputData   = 'yes'; % 'string': ('yes' or 'no') set to 'yes' if artefacts need to be recalculated after channel removal. Set to 'no' when doing the rmchannels, but 'yes' during trialremoval. **Terrible explanation, terrible variable name, just set it to 'no' if you want to remove channels. Will be changed**
OPTIONS.CLEANED.showFigures     = % 'string': ('yes' or 'no'). 
OPTIONS.CLEANED.saveFigures     = % 'string': ('yes' or 'no'). Can only save figures if figures are showed
OPTIONS.CLEANED.inputStr        = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.CLEANED.outputStr       = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.CLEANED.saveData        = OPTIONS.saveData;
OPTIONS.CLEANED.rmTrials        = 'yes'; % 'string' ('yes' or 'no'), set to 'yes' if artifact-ridden trials need to be removed
OPTIONS.CLEANED.optionsFcn      = OPTIONS.pathsScript;
OPTIONS.CLEANED.redefineTrial   = % 'string': ('yes' or 'no'). Set to redefine data to given triallength. Do not set to yes if data is already cut in trials

%% OPTIONS TO APPEND CLEANED DATA
OPTIONS.APPEND.inputStr        = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.APPEND.outputStr       = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.APPEND.saveData         = OPTIONS.saveData;

%% OPTIONS TO CUT DATA INTO TRIALS
OPTIONS.DATACUT.inputStr        = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.DATACUT.outputStr       = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.DATACUT.saveData        = OPTIONS.saveData;
OPTIONS.DATACUT.triallength     = OPTIONS.triallength;

%% WPLI Connetivity calculation options
OPTIONS.WPLICONNECTIVITY.inputStr   = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.WPLICONNECTIVITY.method     = 'wpli_debased'; % method used for calculating connectivity
OPTIONS.WPLICONNECTIVITY.freqOutput = 'powandcsd'; % frequency output used
OPTIONS.WPLICONNECTIVITY.outputStr  = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.WPLICONNECTIVITY.saveData   = OPTIONS.saveData;
OPTIONS.WPLICONNECTIVITY.optionsFcn = OPTIONS.pathsScript;

%% PLI connetivity calculation options
OPTIONS.PLICONNECTIVITY.inputStr    = % 'string': outputstr of previous analysis step, to be used as input for this step
OPTIONS.PLICONNECTIVITY.method      = 'pli'; % method used for calculating connectivity
OPTIONS.PLICONNECTIVITY.freqOutput  = 'powandcsd'; % frequency output used
OPTIONS.PLICONNECTIVITY.outputStr   = % 'string': addition to filename when saving, so that the output filename becomes [currSubject outputStr .mat]
OPTIONS.PLICONNECTIVITY.saveData    = OPTIONS.saveData;
OPTIONS.PLICONNECTIVITY.optionsFcn  = OPTIONS.pathsScript;




