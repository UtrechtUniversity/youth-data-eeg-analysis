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
for iSubjects = startSubject:endSubject
        currSubject = subjectFolderNames{iSubjects};
        
        cfg             = OPTIONS.PREPROC;
        cfg.currSubject = currSubject;
        cfg.quiet       = 'no';
        
        data = bv_preprocResample(cfg);
end

%% CALCULATE ARTEFACTS IN PREPROC DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTPREPROC;
    cfg.quiet       = 'no';
    cfg.currSubject = currSubject;
    
    artefactdef = bv_createArtefactStruct(cfg);
end

%% SET CHANNELS TO REMOVE
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.RMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_removeChannels(cfg);
end

%% PREPROCESSING AGAIN WITH REREF AND WITHOUT REMOVED CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.REREF;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_preprocResample(cfg);
end

%% CALCULATE ARTEFACTS IN EEG DATA WITHOUT POOR CHANNELS
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject
    
    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.ARTFCTRMCHANNELS;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    artefactdef     = bv_createArtefactStruct(cfg);
end

%% REMOVE TRIALS 
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    currSubject = subjectFolderNames{iSubjects};
    
    cfg             = OPTIONS.CLEANED;
    cfg.currSubject = currSubject;
    cfg.quiet       = 'no';
    
    data = bv_cleanData(cfg);
end

%% APPEND DATA
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.APPENDED;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';
    
    data = bv_appendfieldtripdata(cfg);
end

%% Calculate PLI connectivity
clear OPTIONS; setOptions

[startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(1, 'end');
for iSubjects = startSubject:endSubject

    cfg             = OPTIONS.PLICONNECTIVITY;
    cfg.currSubject = subjectFolderNames{iSubjects};
    cfg.quiet       = 'no';
    
    [ connectivity ] = bv_calculatePLI(cfg);
end
