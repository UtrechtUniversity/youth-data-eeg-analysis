function [data] = bv_repairchannels(cfg, data)

inputStr        = ft_getopt(cfg, 'inputStr');
outputStr       = ft_getopt(cfg, 'outputStr');
saveData        = ft_getopt(cfg, 'saveData');
currSubject     = ft_getopt(cfg, 'currSubject');
pathsFcn        = ft_getopt(cfg, 'pathsFcn');

if nargin < 2
    if isempty(pathsFcn)
        error('please add options function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end
    
    disp(currSubject)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata] = bv_check4data(subjectFolderPath);
    
    [~, data] = bv_check4data(subjectFolderPath, inputStr);
    
end


if isfield(subjectdata, 'channels2remove')
    if ~isempty(subjectdata.channels2remove)
        
        fprintf('\t calculating neighbours ... ')
        cfg = []; % start new cfg file for loading data
        cfg.layout = 'biosemi32.lay';
        cfg.method = 'triangulation';
        evalc('neighbours = ft_prepare_neighbours(cfg);');
        fprintf('done! \n')
        
        fprintf(['\t the following channels will be interpolated ... ', ...
            repmat('%s, ',1, length(subjectdata.channels2remove))], subjectdata.channels2remove{:})
        cfg = [];
        cfg.missingchannel = subjectdata.channels2remove';
        cfg.method = 'weighted';
        cfg.neighbours = neighbours;
        cfg.layout = 'biosemi32.lay';
        evalc('data = ft_channelrepair(cfg, data);');
        fprintf('done! \n')
        
        data = bv_sortBasedOnTopo(data);
    end
end

if strcmpi(saveData, 'yes')
        
    bv_saveData(subjectdata, data, outputStr);              % save both data and subjectdata to the drive
    
end