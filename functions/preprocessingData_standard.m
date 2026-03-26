%% BEFORE WE START'
% This is an overview script of all the preprocessing steps needed to be
% taken before analyzing EEG data. 
%% setup subject folders
clear OPTIONS; setOptions
cfg = OPTIONS.CREATEFOLDERS;
bv_createSubjectFolders_YOUth(cfg);

%% PREPROCESSING AND RESAMPLING
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarParfor(length(startSubject:endSubject), "Preprocessing...");
for iSubjects = startSubject:endSubject
        currSubject = subjectFolderNames{iSubjects};
        
        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'no';
        
        data = bv_preprocResample(cfg);
        updateWaitbar();
        
end
%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Artefact detection (preprocessed data)...");
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.quiet       = 'no';
    cfg.currSubject = currSubject;
    
    artefactdef = bv_createArtefactStruct(cfg);
    updateWaitbar(); 
end


%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Find channels to remove...");
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_removeChannels(cfg);
    updateWaitbar();
    
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Preprocess (without removed channels)...");
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_preprocResample(cfg);
    updateWaitbar();

end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Artefact detection (clean preprocessed data)...");
for iSubjects = startSubject:endSubject
    
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    artefactdef     = bv_createArtefactStruct(cfg);
    updateWaitbar();
    
end

%% REMOVE TRIALS 
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Remove poor trials...");
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_cleanData(cfg);
    updateWaitbar();
end

%% APPEND DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Append data...");
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';
    
    data = bv_appendfieldtripdata(cfg);
    updateWaitbar();
    
end



%% Calculate PLI connectivity
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
updateWaitbar = waitbarfor(length(startSubject:endSubject), "Append data...");
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.PLICONNECTIVITY;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';
    
    [ connectivity ] = bv_calculatePLI(cfg);
    updateWaitbar();
end

