%% EEG COVID Pipeline
% This pipeline is meant to preprocess and analyse data from the YOUth
% Cohort study. It is specifically suited to reproduce an ERP analysis
% originally conducted to see the influence of covid measures on emotional
% face processing in infants.

%% Clear workspace before start

restoredefaultpath
clear all
close all
clc
commandwindow

%% Create folder structure 
% !!! Make sure to run this from the home folder of the pipeline !!!
% Otherwise, you will get nested folders.

% Provide directory containing the pipeline
% adjust to the path pointing to where the pipeline is stored on your local machine.
addpath("/home/adamt/projects/youthDM/eegCovid/")
addpath("/home/adamt/projects/youthDM/eegCovid/functions/")

% Create new analysis folder
makefolders = 1; % set to 1 to create analysis directories (only set to 0 if the same exact analysis folder already exists)

if makefolders == 1
    label         = "" ; % label to add to foldername
    overwrite     = true; % boolean [true or false] whether to overwrite earlier analysis with the same folder name

    bv_createNewAnalysis(label,overwrite)
end

%% Provide correct paths
edit("setPaths.m")

%% Set paths
setPaths

%% Set options (optional)
% If the default settings are okay, this step can be skipped
edit setOptions

%% Preprocessing 

preprocessingData
