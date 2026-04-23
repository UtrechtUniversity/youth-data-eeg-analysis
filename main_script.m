%% EEG COVID Pipeline
% This pipeline is meant to preprocess and analyse data from the YOUth
% Cohort study. It is specifically suited to reproduce a network 
% connectivity analysis.

%% Clear workspace before start

restoredefaultpath
clear all; close all; clc;

%% Create folder structure 

% Provide directory containing the pipeline and its functions
thisFile = mfilename('fullpath');
if ~contains(thisFile, 'main_script') || isempty(thisFile)
    thisFile = matlab.desktop.editor.getActiveFilename;
end
scriptDir = fileparts(thisFile);
addpath(scriptDir);
addpath(scriptDir + "/functions/");
cd(scriptDir);

% Create new analysis folder
makefolders = 1; % set to 1 to create analysis directories (only set to 0 if the same exact analysis folder already exists)

if makefolders == 1
    label         = "" ; % label to add to foldername
    overwrite     = true; % boolean [true or false] whether to overwrite earlier analysis with the same folder name

    bv_createNewAnalysis(label,overwrite)
end

%% Provide correct paths
% If the default paths are okay, this step can be skipped
edit("setPaths.m")

%% Set paths
setPaths

%% Set options (optional)
% If the default settings are okay, this step can be skipped
edit setOptions

%% Preprocessing 

preprocessingData
