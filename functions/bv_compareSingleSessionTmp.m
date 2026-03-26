%% SET THE SUBJECT RANGE BEFORE RUNNING
startSubject = 1;
endSubject ='end';
saveResults = 'yes';
saveFigures = 'no';

eval('setPaths')
eval('setOptions')

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};

if ischar(startSubject)
    startSubject = find(~cellfun(@isempty, strfind(subjectFolderNames, startSubject)));
end
if ischar(endSubject)
    if strcmp(endSubject, 'end')
        endSubject = length(subjectFolderNames);
    else
        endSubject = find(~cellfun(@isempty, strfind(subjectFolderNames, endSubject)));
    end
end

%% SPLIT CLEANED DATA
eval('setOptions')
clear subjects R Ws
for iSubjects = startSubject:endSubject
    currSubject = subjectFolderNames{iSubjects};
    disp(currSubject)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, wpli_debiased1, wpli_debiased2] = bv_check4data(subjectFolderPath, 'WPLI_DEBIASED1', 'WPLI_DEBIASED2');
    
    if ~exist('Ws', 'var')
        Ws = zeros([size(wpli_debiased1. wpli_debiasedspctrm) length(startSubject:endSubject) 2]);
    end
    Ws(:,:,:,iSubjects,1) = wpli_debiased1.wpli_debiasedspctrm;
    Ws(:,:,:,iSubjects,2) = wpli_debiased2.wpli_debiasedspctrm;

    cfg = [];
    R(iSubjects,:) = bv_compareSingleSession(cfg, wpli_debiased1, wpli_debiased2);
    subjects{iSubjects} = currSubject;
    
    if strcmpi(saveFigures, 'yes')
        plot(wpli_debiased1.freq, R(iSubjects,:), 'LineWidth', 2)
        set(gca, 'XLim', [0 100])
        set(gca, 'YLim', [-0.1 1])
        
        fprintf('\t saving figure ... ')
        saveas(gcf, [PATHS.RESULTFIGURES filesep currSubject '_correlationPerFreq.png'])
        fprintf('done! \n')
        close all
    end
end
dims = 'chan-chan-freq-subj-session';
freq = wpli_debiased1.freq;
subjects = subjects; 
chans = wpli_debiased1.label;

if strcmpi(saveResults, 'yes')
    fprintf('SAVING RESULTS ... ')
    save([PATHS.RESULTS filesep 'wpli_debiased_oneSession.mat'], '-v7.3', 'dims', 'freq', 'subjects', 'chans', 'Ws', 'R')
    fprintf('done! \n')
end
