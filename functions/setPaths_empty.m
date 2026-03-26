% set all the paths necessary for analysis. Change according to your own
% needs. Save this file to your PATHS.ROOT folder so it can always be found
% by matlab during analysis

% Paths to already existing folders
PATHS.ROOT          = % analyses folder (subject & figure folders will be created here)
PATHS.HOME          = % path to home folder (where you can find RAWS and PRPEROC usually)
PATHS.RAWS          = [PATHS.HOME filesep 'RAW']; % path to the directory of raw EEG files
PATHS.SUBFUNCTIONS  = [PATHS.HOME filesep 'subfunctions'];    % path to your subfunctions directory (place the functions made specifically for your dataset here e.g. trialfun)
PATHS.FILES         = [PATHS.HOME filesep 'files'];
PATHS.PREPROC       = [PATHS.HOME filesep 'PREPROC']; % path to the preproc folder

% Paths to folders to be created 
PATHS.SUBJECTS      = [PATHS.ROOT filesep 'Subjects'];        % path to subject directory
PATHS.RESULTS       = [PATHS.ROOT filesep 'results'];         % path to results directory
PATHS.REMOVED       = [PATHS.SUBJECTS filesep 'removed'];     % path to the remove subjects directory
PATHS.FIGURES       = [PATHS.ROOT filesep 'figures'];         % path to analysis figure directory
PATHS.RESULTFIGURES = [PATHS.RESULTS filesep 'figures'];      % path to results figure directory
PATHS.CONFIG        = [PATHS.ROOT filesep 'config'];          % path where options are saved in a mat file

% create, if necessary the folders
if ~exist(PATHS.SUBJECTS, 'dir')
    mkdir(PATHS.SUBJECTS)
end
if ~exist(PATHS.RESULTS, 'dir')
    mkdir(PATHS.RESULTS)
end
if ~exist(PATHS.FIGURES, 'dir')
    mkdir(PATHS.FIGURES)
end
if ~exist(PATHS.SUBFUNCTIONS, 'dir')
    mkdir(PATHS.SUBFUNCTIONS)
end
if ~exist(PATHS.RESULTFIGURES, 'dir')
    mkdir(PATHS.RESULTFIGURES)
end
if ~exist(PATHS.REMOVED, 'dir')
    mkdir(PATHS.REMOVED)
end
if ~exist(PATHS.CONFIG, 'dir')
    mkdir(PATHS.CONFIG)
end
    
% add fieldtrip and the subfunctions to your matlab path
PATHS.FTPATH = '/Users/Bauke/Matlab_Toolboxes/EEG/fieldtrip-20160120/';

addpath(PATHS.SUBFUNCTIONS)
addpath(pwd)
addpath(PATHS.FTPATH)
ft_defaults