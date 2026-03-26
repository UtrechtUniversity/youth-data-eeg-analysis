function bv_removeBasedOnTriggers(cfg)

% read out from configuration structure
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');
triggers    = ft_getopt(cfg, 'triggers');

% load in standard options and paths
eval(optionsFcn);
eval(pathsFcn);

switch OPTIONS.dataType
    case 'bdf'
        rawFiles = dir([PATHS.RAWS filesep '*.bdf']);
    case 'eeg'
        rawFiles = dir([PATHS.RAWS filesep '*.eeg']);
end

for i = 1:length(rawFiles)
    currFile = rawFiles(i).name;
    disp(currFile)
    event = ft_read_event([PATHS.RAWS filesep currFile]);
    
    EVtype = {event.type}';
    statusIndx = strcmp(EVtype, 'STATUS');
    event(~statusIndx) = [];
    
    EVvalue = [event.value];
    [~,b] = ismember(EVvalue, triggers);
    
    if sum(b) == 0
        fprintf('\t no triggers found in %s-file \n', OPTIONS.dataType)
        fprintf('\t moving raw file to %s ... ', [PATHS.RAWS filesep 'removed'])
        if ~exist([PATHS.RAWS filesep 'removed'], 'dir')
            mkdir([PATHS.RAWS filesep 'removed'])
        end
        movefile([PATHS.RAWS filesep currFile], [PATHS.RAWS filesep 'removed'])
        fprintf('done! \n')
    else
        
        fprintf('\t triggers found! \n')
        a = hist(b(b~=0),length(triggers));
        
        if any(a==0)
            warning('at least one trigger not found')
        end
        
        tmp = [triggers; a];
        tmp2 = tmp(:)';
        tmp3 = strsplit(num2str(tmp2));
        
        fprintf(['\t instances of triggers \n\t\t' repmat('%s: %s \t ', 1, length(triggers)) '\n'], tmp3{:})
    end
end

