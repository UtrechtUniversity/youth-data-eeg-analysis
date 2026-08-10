%% Verification
% This is a script to check if all the prerequisites are present for the
% pipeline to run without problems.

%% Clear workspace first

restoredefaultpath
clear all; clc;

%% MATALB Version

fprintf("--- Pipeline Prerequisites Check ---\n\n");

matlb = version;
fprintf("MATLAB version %s detected\n", matlb);

if isMATLABReleaseOlderThan("R2025b")
    warning("✗ MATLAB version might be too old to run the pipeline.")
else
    disp('✓ MATLAB version suitable for running the pipeline.')
end

%% Toolboxes
displayNames = {'Image Processing Toolbox', ...
                'Optimization Toolbox', ...
                'Signal Processing Toolbox', ...
                'Statistics and Machine Learning Toolbox'};

licenseNames = {'Image_Toolbox', ...
                'Optimization_Toolbox', ...
                'Signal_Toolbox', ...
                'Statistics_Toolbox'};

hasLicense = cellfun(@(n) license('test', n), licenseNames);
missing = displayNames(~hasLicense);

if ~isempty(missing)
    warning('✗ Missing toolbox(es) or license(s) detected.')
    disp('Please install or enable the following toolboxes:')
    disp(missing(:))
else
    disp('✓ All required toolboxes are installed and licensed.')
end

%% Fieldtrip
thisFile = mfilename('fullpath');
if ~contains(thisFile, 'verify') || isempty(thisFile)
    thisFile = matlab.desktop.editor.getActiveFilename;
end
scriptDir = fileparts(thisFile);
ftpath = fullfile(scriptDir, 'fieldtrip');
addpath(ftpath)
%%
try
    initOutput = evalc('ft_defaults');
catch ME
    error('pipeline:FtMissing', ...
          '✗ FieldTrip failed to initialise:\n%s', ME.message);
end

% direct project dependencies only; FieldTrip's own internal deps are not checked
required = {'ft_artifact_jump', 'ft_channelrepair', 'ft_defaults', ...
            'ft_definetrial', 'ft_getopt', 'ft_prepare_layout', ...
            'ft_prepare_neighbours', 'ft_preprocessing', 'ft_read_event', ...
            'ft_read_header', 'ft_redefinetrial', 'ft_resampledata', ...
            'ft_selectdata'};
missing = required(cellfun(@(f) isempty(which(f)), required));

if ~isempty(missing)
    fprintf(2, '⚠ FieldTrip loaded but missing function(s): %s\n', ...
            strjoin(missing, ', '));
    fprintf(2, '  Likely a partial/broken FieldTrip install or path issue.\n');
    fprintf(2, '%s\n', initOutput);
else
    fprintf(1, '✓ FieldTrip initialised cleanly, all required functions available.\n');
end

%% Clean up

restoredefaultpath;
clear required missing matlb licenseNames initOutput hasLicense ...
      ftpath displayNames scriptDir thisFile RESTOREDEFAULTPATH_EXECUTED;
