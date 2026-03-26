% This is an overview script of all the preprocessing steps needed taken to
% calculate the networks in EEG data. This function uses parallel processing.
% This is recommended to use if you run this function on DRE or on any
% computer with multiple cores (to speed up the process). Note that due the
% parallelization, outputs into the command line window are generally
% limited. It is therefore not recommended to use this script if you are
% new to this pipeline.
%% setup subject folders
clear OPTIONS; setOptions

cfg = OPTIONS.CREATEFOLDERS;
bv_createSubjectFolders_YOUth(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Preprocessing...");
parfor iSubjects = startSubject:endSubject
    
        
        currSubject = subjectFolderNames{iSubjects};
        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'yes';
        cfg.overwrite   = 'no';
        
        data = bv_preprocResample(cfg);
        updateWaitbar();
        
end

%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Artefact detection (preprocessed data)...");
parfor iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'yes';
    
    artefactdef = bv_createArtefactStruct(cfg);
    updateWaitbar(); 
end


%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Find channels to remove...");
parfor iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'yes';
    
    data = bv_removeChannels(cfg);
    updateWaitbar();
    
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Preprocess (without removed channels)...");
parfor iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'yes';
    
    data = bv_preprocResample(cfg);
    updateWaitbar();

end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Artefact detection (clean preprocessed data)...");
parfor iSubjects = startSubject:endSubject
    
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'yes';
    
    artefactdef = bv_createArtefactStruct(cfg);
    updateWaitbar();
    
end

%% REMOVE TRIALS 
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Remove poor trials...");
parfor iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'yes';
    
    data = bv_cleanData(cfg);
    updateWaitbar();
end

%% APPEND DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Append data...");
parfor iSubjects = startSubject:endSubject

    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'yes';
    
    data = bv_appendfieldtripdata(cfg);
    updateWaitbar();
    
end



%% Calculate PLI connectivity
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Append data...");
parfor iSubjects = startSubject:endSubject

    cfg             = OPTIONS.PLICONNECTIVITY;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'yes';
    
    [ connectivity ] = bv_calculatePLI(cfg);
    updateWaitbar();
end

