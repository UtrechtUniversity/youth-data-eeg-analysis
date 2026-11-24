%% Settings for Preprocessing
% This file holds the settings of all preprocessing steps. A copy is placed in
% every new analysis folder (as setOptions.m), so it also records the
% settings the analysis was run with. Change the values to the right of the
% '=' signs; the text after the '%' explains each setting. The power and
% network-metric settings build on this file.
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
% settings shared by several steps
OPTIONS.saveData                = 'yes';      % 'string': Save the results of the steps in the subject folders: 'yes' or 'no' (stored in subjectdata)
OPTIONS.triallength             = 3;          % [ number ]: Length (seconds) of the epochs the connectivity metric (PLI) is calculated on
OPTIONS.artifacttrllength       = 1;          % [ number ]: Length (seconds) of the short segments in which artefacts are detected and removed
OPTIONS.pathsScript             = 'setPaths'; % 'string': Name of the paths script (normally leave as is)

%% Create subject folders
% see bv_createSubjectFolders_NewStruct
OPTIONS.CREATEFOLDERS.pathsFcn      = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)
OPTIONS.CREATEFOLDERS.inputName     = [];                  % 'string': Only needed when dataType is 'mat' (see below): name of the earlier step whose saved result is the input (e.g. 'PREPROC')
OPTIONS.CREATEFOLDERS.rawdelim      = '_';                 % 'string': Character that separates the parts of the raw file names (e.g. '_' in B00002_10m.bdf)
OPTIONS.CREATEFOLDERS.sfoldername   = {'pseudo', 'wave'};  % { cell }: Parts of the names that make up the subject folder name, e.g. {'pseudo','wave'} gives B00002_10m
OPTIONS.CREATEFOLDERS.overwrite     = 'yes';               % 'string': 'yes' = create the folders again for subjects that already exist; 'no' = skip them
OPTIONS.CREATEFOLDERS.dataType      = 'bdf';               % 'string': Type of the raw recordings: 'bdf', 'edf', 'eeg' or 'mat'
OPTIONS.CREATEFOLDERS.rawlabel      = {'pseudo', 'wave'};  % { cell }: Names for the parts of the raw file name, in order (split at rawdelim); [] skips a part
OPTIONS.CREATEFOLDERS.folderlabel   = {'wave', 'pseudo'};  % { cell }: Names for the folder levels below the raw data folder, in order
OPTIONS.CREATEFOLDERS.folderPattern = {'', 'B'};           % { cell }: Text a folder name has to match, one per folder level; '' accepts every folder
OPTIONS.CREATEFOLDERS.filePattern   = '';                  % 'string': Text a file name has to match; '' accepts every file

%% Preprocessing options
% Reads the raw recording, resamples and filters it, and cuts it into trials
% around the triggers. See bv_preprocResample
OPTIONS.PREPROC.pathsFcn        = OPTIONS.pathsScript;           % 'string': Name of the paths script (normally leave as is)
OPTIONS.PREPROC.outputName      = 'PREPROC';                     % 'string': Name the result is saved under (file: [subject]_PREPROC.mat)
OPTIONS.PREPROC.saveData        = OPTIONS.saveData;              % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.PREPROC.overwrite       = 'yes';                         % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.PREPROC.channels        = {'EEG'};                       % { cell }: Channels to read in; {'EEG'} = all EEG channels (see ft_channelselection)
OPTIONS.PREPROC.chanindx        = [];                            % [ number ]: Alternatively, the indices of the channels to read in (overrules 'channels'); [] = not used
OPTIONS.PREPROC.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': Name of the function that cuts the recording into trials around the triggers; '' = no cutting (see ft_definetrial)
OPTIONS.PREPROC.pretrig         = [];                            % [ number ]: Seconds to include before each trigger; [] = default of the trial function (0 s)
OPTIONS.PREPROC.posttrig        = [];                            % [ number ]: Seconds to include after each trigger; [] = default of the trial function (60 s)
OPTIONS.PREPROC.resampleFs      = 512;                           % [ number ]: New sampling rate in Hz; [] = no resampling (see ft_resampledata)
OPTIONS.PREPROC.hpfreq          = 0.16;                          % [ number ]: High-pass filter cut-off in Hz (removes slow drifts) (see ft_preprocessing)
OPTIONS.PREPROC.lpfreq          = 70;                            % [ number ]: Low-pass filter cut-off in Hz (removes fast noise) (see ft_preprocessing)
OPTIONS.PREPROC.notchfreq       = 50;                            % [ number ]: Notch filter frequency in Hz (removes power-line noise) (see ft_preprocessing)
OPTIONS.PREPROC.filttype        = [];                            % 'string': Filter type: 'but' (Butterworth) or 'firws' (windowed-sinc); [] = 'but' (see ft_preprocessing)
OPTIONS.PREPROC.reref           = 'no';                          % 'string': Re-reference the data: 'yes' or 'no' (see ft_preprocessing)
OPTIONS.PREPROC.refelec         = '';                            % 'string': Reference electrode(s), only used if reref = 'yes'; 'all' = average of all channels; '' = 'all' (see ft_preprocessing)
OPTIONS.PREPROC.refmethod       = 'avg';                         % 'string': How the reference is subtracted: 'avg' = average of the reference electrodes (see ft_preprocessing)
OPTIONS.PREPROC.removechans     = 'no';                          % 'string': Leave out the channels flagged as bad when reading in the data: 'yes' or 'no' (stored in subjectdata.flaggedChannels)
OPTIONS.PREPROC.channels2remove = {};                            % { cell }: Channels to leave out instead of the flagged ones (only if removechans = 'yes'); {} = the flagged ones
OPTIONS.PREPROC.interpolate     = 'no';                          % 'string': Replace the left-out channels by interpolation from their neighbours: 'yes' or 'no' (needs removechans = 'yes') (see ft_channelrepair)
OPTIONS.PREPROC.interpMethod    = 'average';                     % 'string': Interpolation method: 'average' = mean of the neighbouring channels (see ft_channelrepair)
OPTIONS.PREPROC.waveletThresh   = 'no';                          % 'string': Wavelet-based artefact cleaning (HAPPE v3, needs the Wavelet Toolbox): 'yes' or 'no'

%% Calculate artifact values after preprocessing
% Measures how noisy each short segment of each channel is, as the basis for
% finding bad channels. See bv_createArtefactStruct
OPTIONS.ARTFCTPREPROC.pathsFcn        = OPTIONS.pathsScript;                        % 'string': Name of the paths script (normally leave as is)
OPTIONS.ARTFCTPREPROC.inputName       = 'PREPROC';                                  % 'string': Saved result the artefacts are calculated on
OPTIONS.ARTFCTPREPROC.outputName      = 'ARTFCTBEFORE';                             % 'string': Name the artefact values are saved under
OPTIONS.ARTFCTPREPROC.saveData        = OPTIONS.saveData;                           % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.ARTFCTPREPROC.overwrite       = 'yes';                                      % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.ARTFCTPREPROC.cutintrials     = 'yes';                                      % 'string': Cut the data into short segments first: 'yes' or 'no'
OPTIONS.ARTFCTPREPROC.triallength     = OPTIONS.artifacttrllength;                  % [ number ]: Length (seconds) of those segments
OPTIONS.ARTFCTPREPROC.analyses        = {'kurtosis','variance', 'flatline', 'abs'}; % { cell }: Artefact measures: kurtosis, variance, flatline (flat signal), abs (largest absolute amplitude), or 'all'

%% Remove channels options
% Flags channels that are bad in too many segments, and removes subjects with
% too many bad channels. Only flag channels that are flat or extremely noisy,
% so much so that they would distort the average reference. The thresholds
% below decide when a segment counts as bad for a channel.
% See bv_removeChannels
lims = struct;
lims.abs = 250;       % [ number ]: largest allowed absolute amplitude (uV)
lims.flatline = 0.1;  % [ number ]: flat-signal measure (1 ./ SD.^2); higher = flatter
lims.kurtosis = 10;   % [ number ]: peakedness of the signal distribution
lims.variance = 2000; % [ number ]: variance of the signal (uV^2)

OPTIONS.RMCHANNELS.pathsFcn        = OPTIONS.pathsScript;            % 'string': Name of the paths script (normally leave as is)
OPTIONS.RMCHANNELS.inputName       = 'PREPROC';                      % 'string': Saved result the channels are checked on
OPTIONS.RMCHANNELS.outputName      = 'PREPROCRMCHANNELS';            % 'string': Name the result is saved under (the re-referencing step below uses the same name)
OPTIONS.RMCHANNELS.artefactData    = 'ARTFCTBEFORE';                 % 'string': Saved artefact values to use (from the artefact step above)
OPTIONS.RMCHANNELS.saveData        = OPTIONS.saveData;               % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.RMCHANNELS.overwrite       = 'yes';                          % 'string': 'yes' = redo and replace an existing result (needed here, as the re-referencing step below saves under the same name)
OPTIONS.RMCHANNELS.lims            = lims;                           % struct: Thresholds above which a segment counts as bad for a channel (see above)
OPTIONS.RMCHANNELS.maxpercbad      = 40;                             % [ number ]: A channel is flagged when more than this percentage of its segments is bad
OPTIONS.RMCHANNELS.maxbadchans     = 3;                              % [ number ]: Subjects with more flagged channels than this are removed
OPTIONS.RMCHANNELS.expectedtrials  = 360./OPTIONS.artifacttrllength; % [ number ]: Number of segments in a full recording that the percentage is based on (360 s / segment length)
OPTIONS.RMCHANNELS.repairchans     = 'no';                           % 'string': Replace the flagged channels by interpolation already in this step: 'yes' or 'no'

%% Preprocessing + reref options without removed channels
% Repeats the preprocessing, now leaving out the flagged channels,
% interpolating them from their neighbours and re-referencing to the average
% of all channels. See bv_preprocResample
OPTIONS.REREF.pathsFcn        = OPTIONS.pathsScript;           % 'string': Name of the paths script (normally leave as is)
OPTIONS.REREF.outputName      = 'PREPROCRMCHANNELS';           % 'string': Name the result is saved under (file: [subject]_PREPROCRMCHANNELS.mat)
OPTIONS.REREF.saveData        = OPTIONS.saveData;              % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.REREF.overwrite       = 'yes';                         % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.REREF.channels        = {'EEG'};                       % { cell }: Channels to read in; {'EEG'} = all EEG channels (see ft_channelselection)
OPTIONS.REREF.chanindx        = [];                            % [ number ]: Alternatively, the numbers of the channels to read in (overrules 'channels'); [] = not used
OPTIONS.REREF.trialfun        = 'trialfun_YOUth_connectivity'; % 'string': Name of the function that cuts the recording into trials around the triggers; '' = no cutting (see ft_definetrial)
OPTIONS.REREF.pretrig         = [];                            % [ number ]: Seconds to include before each trigger; [] = default of the trial function (0 s)
OPTIONS.REREF.posttrig        = [];                            % [ number ]: Seconds to include after each trigger; [] = default of the trial function (60 s)
OPTIONS.REREF.resampleFs      = 512;                           % [ number ]: New sampling rate in Hz; [] = no resampling (see ft_resampledata)
OPTIONS.REREF.hpfreq          = 0.16;                          % [ number ]: High-pass filter cut-off in Hz (removes slow drifts) (see ft_preprocessing)
OPTIONS.REREF.lpfreq          = 70;                            % [ number ]: Low-pass filter cut-off in Hz (removes fast noise) (see ft_preprocessing)
OPTIONS.REREF.notchfreq       = 50;                            % [ number ]: Notch filter frequency in Hz (removes power-line noise) (see ft_preprocessing)
OPTIONS.REREF.filttype        = [];                            % 'string': Filter type: 'but' (Butterworth) or 'firws' (windowed-sinc); [] = 'but' (see ft_preprocessing)
OPTIONS.REREF.reref           = 'yes';                         % 'string': Re-reference the data: 'yes' or 'no' (see ft_preprocessing)
OPTIONS.REREF.refelec         = 'all';                         % 'string': Reference electrode(s); 'all' = average of all channels (see ft_preprocessing)
OPTIONS.REREF.refmethod       = 'avg';                         % 'string': How the reference is subtracted: 'avg' = average of the reference electrodes (see ft_preprocessing)
OPTIONS.REREF.removechans     = 'yes';                         % 'string': Leave out the channels flagged as bad when reading in the data: 'yes' or 'no' (stored in subjectdata.flaggedChannels)
OPTIONS.REREF.channels2remove = {};                            % { cell }: Channels to leave out instead of the flagged ones (only if removechans = 'yes'); {} = the flagged ones
OPTIONS.REREF.interpolate     = 'yes';                         % 'string': Replace the left-out channels by interpolation from their neighbours: 'yes' or 'no' (needs removechans = 'yes'; see ft_channelrepair)
OPTIONS.REREF.interpMethod    = 'average';                     % 'string': Interpolation method: 'average' = mean of the neighbouring channels (see ft_channelrepair)
OPTIONS.REREF.waveletThresh   = 'no';                          % 'string': Wavelet-based artefact cleaning (HAPPE v3, needs the Wavelet Toolbox): 'yes' or 'no'

%% Calculate artifact values after preprocessing
% Measures the artefacts again, now on the re-referenced data, as the basis
% for removing bad segments. See bv_createArtefactStruct
OPTIONS.ARTFCTRMCHANNELS.pathsFcn        = OPTIONS.pathsScript;                        % 'string': Name of the paths script (normally leave as is)
OPTIONS.ARTFCTRMCHANNELS.inputName       = 'PREPROCRMCHANNELS';                        % 'string': Saved result the artefacts are calculated on
OPTIONS.ARTFCTRMCHANNELS.outputName      = 'ARTFCTRMCHANS';                            % 'string': Name the artefact values are saved under
OPTIONS.ARTFCTRMCHANNELS.saveData        = OPTIONS.saveData;                           % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.ARTFCTRMCHANNELS.overwrite       = 'yes';                                      % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.ARTFCTRMCHANNELS.cutintrials     = 'yes';                                      % 'string': Cut the data into short segments first: 'yes' or 'no'
OPTIONS.ARTFCTRMCHANNELS.triallength     = OPTIONS.artifacttrllength;                  % [ number ]: Length (seconds) of those segments
OPTIONS.ARTFCTRMCHANNELS.analyses        = {'kurtosis','variance', 'flatline', 'abs'}; % { cell }: Artefact measures: kurtosis, variance, flatline (flat signal), abs (largest amplitude), or 'all'

%% Clean data options
% Removes the short segments with artefacts: a segment that exceeds any of the
% thresholds below is discarded. See bv_cleanData
lims = struct;
lims.abs = 250;       % [ number ]: largest allowed absolute amplitude (uV)
lims.flatline = 0.1;  % [ number ]: flat-signal measure (1 ./ SD.^2); higher = flatter
lims.kurtosis = 10;   % [ number ]: peakedness of the signal distribution
lims.variance = 2000; % [ number ]: variance of the signal (uV^2)

OPTIONS.CLEANED.pathsFcn           = OPTIONS.pathsScript;            % 'string': Name of the paths script (normally leave as is)
OPTIONS.CLEANED.inputName          = 'PREPROCRMCHANNELS';            % 'string': Saved result the bad segments are removed from
OPTIONS.CLEANED.outputName         = 'CLEANED';                      % 'string': Name the cleaned result is saved under
OPTIONS.CLEANED.artefactData       = 'ARTFCTRMCHANS';                % 'string': Saved artefact values to use (from the artefact step above)
OPTIONS.CLEANED.saveData           = OPTIONS.saveData;               % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.CLEANED.cleanEpochs        = 'yes';                          % 'string': Remove the noisy segments, those with an artefact measure above a limit below: 'yes' or 'no' ('no' keeps every segment and the limits are not used; normally leave as is)
OPTIONS.CLEANED.lims               = lims;                           % struct: Thresholds above which a segment is discarded (see above)
OPTIONS.CLEANED.minEpochs          = [];                             % [ number ]: Minimum number of clean segments a subject needs; a subject with fewer is removed. [] = no minimum (a subject is then only removed when no clean segment is left)
OPTIONS.CLEANED.stage              = 'artefact';                     % 'string': Pipeline stage of this cleaning, so its segment counts are stored separately from those of the power stage (normally leave as is)
OPTIONS.CLEANED.saveCleanData      = 'yes';                          % 'string': 'yes' = skip subjects that already have a result (unless overwrite = 'yes')
OPTIONS.CLEANED.overwrite          = 'no';                           % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it
OPTIONS.CLEANED.calculateDataloss  = 'no';                           % 'string': Calculate the percentage of data lost by the cleaning and store it for the subject: 'yes' or 'no'
OPTIONS.CLEANED.dataLossLabel      = 'dataLossAfter';                % 'string': Name under which that percentage is stored (only if calculateDataloss = 'yes')
OPTIONS.CLEANED.expectedtrials     = 360./OPTIONS.artifacttrllength; % [ number ]: Number of segments in a full recording (only needed if calculateDataloss = 'yes')

%% Append
% Joins the remaining clean segments back together. See bv_appendfieldtripdata
OPTIONS.APPENDED.pathsFcn     = OPTIONS.pathsScript; % 'string': Name of the paths script (normally leave as is)
OPTIONS.APPENDED.inputName    = 'CLEANED';           % 'string': Saved result whose clean segments are joined together
OPTIONS.APPENDED.outputName   = 'APPEND';            % 'string': Name the joined result is saved under
OPTIONS.APPENDED.saveData     = OPTIONS.saveData;    % 'string': Save the result of this step in the subject's folder: 'yes' or 'no'
OPTIONS.APPENDED.overwrite    = 'no';                % 'string': 'yes' = redo and replace an existing result; 'no' = skip subjects that already have it

%% Subject summary collection options
% Collects the information of all subjects in one file. See bv_collectSubjectSummary
OPTIONS.SUBJECTSUMMARY.outputFile = 'SubjectSummary.csv'; % 'string': Name of the summary file with one row per subject (saved in the summary folder, PATHS.SUMMARY)
OPTIONS.SUBJECTSUMMARY.pathsFcn   = OPTIONS.pathsScript;  % 'string': Name of the paths script (normally leave as is)
