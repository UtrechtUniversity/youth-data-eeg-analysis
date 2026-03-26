function bv_checkBdfFiles(bdffolder, triggers)

rootDir = pwd;

cd(bdffolder)

rmDir = [rootDir filesep bdffolder filesep 'removed'];
if ~exist(rmDir, 'dir')
    mkdir(rmDir)
end

bdffiles = dir('*.bdf');
bdffileNames = {bdffiles.name};

for iBDF = 1:length(bdffileNames)
    currBdf = bdffileNames{iBDF};
    
    disp(currBdf)
    
    event = ft_read_event(currBdf);
    
    EVtype = {event.type}';
    statusIndx = strcmp(EVtype, 'STATUS');
    event(~statusIndx) = [];
    
    EVvalue = [event.value]';
    EVsample = [event.sample]';
    
    if sum(ismember(triggers, EVvalue)) == 0
        movefile(currBdf, rmDir)
        fprintf('\t no correct triggers found in event file, removing bdf-file \n')
    else
        fprintf('\t correct triggers found in event file, not removing \n')
    end
end

    
