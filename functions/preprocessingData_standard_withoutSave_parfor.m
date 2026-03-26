% This is an overview script of all the preprocessing steps needed taken to
% calculate the networks in EEG data. This is the version of the script
% that doesn't save intermediate steps. This is generally not
% recommendended, but if you have limited space on your harddrive, this is 
% the script to use. Additionally, this function uses parallel processing.
% This is recommended to use if you run this function on DRE or on any
% computer with multiple cores (to speed up the process). Note that due the
% parallelization, outputs into the command line window are generally
% limited. It is therefore not recommended to use this script if you are
% new to this pipeline.
%
% Written by Bauke van der Velde, 2018-2024

%% setup subject folders
clear OPTIONS; setOptions

cfg = OPTIONS.CREATEFOLDERS;
bv_createSubjectFolders_YOUth(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptions
[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
subjectFolderNames = subjectFolderNames(startSubject:endSubject);

updateWaitbar = waitbarParfor(length(subjectFolderNames), "Preprocessing...");

if exist('p', 'var')
    delete(p)
end
p = parpool('local');
nw = p.NumWorkers;
M = nw-1;

parfor(iSubjects = 1:length(subjectFolderNames),7)
    try
        currSubject = subjectFolderNames{iSubjects};
        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        data = bv_preprocResample(cfg);

        %% CALCULATE ARTEFACTS IN PREPROC DATA

        cfg             = OPTIONS.ARTFCTPREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        artefactdef = bv_createArtefactStruct(cfg, data);

        %% SET CHANNELS TO REMOVE

        cfg             = OPTIONS.RMCHANNELS;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        [data, sdata] = bv_removeChannels(cfg, data, artefactdef);

        %% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS

        cfg             = OPTIONS.REREF;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        data = bv_preprocResample(cfg);

        %% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS

        cfg             = OPTIONS.ARTFCTRMCHANNELS;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        artefactdef = bv_createArtefactStruct(cfg, data);

        %% REMOVE TRIALS

        cfg             = OPTIONS.CLEANED;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        data = bv_cleanData(cfg, data, artefactdef);

        %% APPEND DATA

        cfg             = OPTIONS.APPENDED;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'no';

        data = bv_appendfieldtripdata(cfg, data);


        %% Calculate PLI connectivity

        cfg             = OPTIONS.PLICONNECTIVITY;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.saveData    = 'yes';
        cfg.pathsFcn    = 'setPaths';

        [ connectivity ] = bv_calculatePLI(cfg, data);
        updateWaitbar();
    catch
        warning([subjectFolderNames{iSubjects}, ': %s'], lasterr)
    end
end

