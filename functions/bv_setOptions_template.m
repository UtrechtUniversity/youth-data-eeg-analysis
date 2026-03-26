% standard global variables file. Change according to your own needs.

PATHS.ROOT          =   '~/_Research/FE/';  % topfolder, with the general functions and a folder with RAW data and a folder with the necessary subfunctions 
rawDir              =   'RAW';              % name of the folder with all the RAW data
sDir                =   'Subjects';         % name of the to be created Subject folder
sDirString          =   'pp';               % string that is added to each subjectfolder (followed by a number)
resultsDir          =   'Results';          % name of the to be create results folder
QCDir               =   'QC';               % name of the QualityControl folder
dataType            = 	'bdf';              % set data type (f.e. 'eeg', 'bdf')
triggers.value      =   [129 139];          % trigger values of interest
triggers.label      =   {'Non Social', 'Social'};   % respective labels for the values
channels2beAnalyzed =   'eeg';              % set channels2beAnalyzed (can be 'eeg')

PATHS.SUBJECTS      = [PATHS.ROOT filesep sDir];               % path to subject directory
PATHS.RESULTS       = [PATHS.ROOT filesep resultsDir];         % path to results directory
PATHS.RAWS          = [PATHS.ROOT filesep rawDir];             % path to the raw directory
PATHS.REMOVED       = [PATHS.SUBJECTS filesep 'removed'];      % path to the remove subjects directory
PATHS.SUBFUNCTIONS  = [PATHS.ROOT filesep 'subfunctions'];     % path to functions specific for this dataset
PATHS.FIGURES       = [PATHS.ROOT filesep 'figures'];
PATHS.DFILEDIR      = [PATHS.ROOT filesep 'dataFilesForAllSubjects'];
PATHS.QCDir         = [PATHS.ROOT filesep QCDir];

% create, if necessary the folders
if ~exist(PATHS.SUBJECTS, 'dir')
    mkdir(PATHS.SUBJECTS)
end
if ~exist(PATHS.RESULTS, 'dir')
    mkdir(PATHS.RESULTS)
end
if ~exist(PATHS.RAWS, 'dir')
    mkdir(PATHS.RAWS)
end
if ~exist(PATHS.DFILEDIR, 'dir')
    mkdir(PATHS.DFILEDIR)
end
if ~exist(PATHS.REMOVED, 'dir')
    mkdir(PATHS.REMOVED)
end

% add fieldtrip and the subfunctions to your matlab path
PATHS.FTPATH = '/Users/Bauke/Matlab_Toolboxes/EEG/fieldtrip-20160120/';

addpath(PATHS.SUBFUNCTIONS)
addpath(pwd)
addpath(PATHS.FTPATH)
ft_defaults