function [artefactdef] = bv_add2ArtefactStruct(cfg, data, artefactdef)

inputStr        = ft_getopt(cfg, 'inputStr');
artefactdefStr  = ft_getopt(cfg, 'artefactdefStr');
saveData        = ft_getopt(cfg, 'saveData');
currSubject     = ft_getopt(cfg, 'currSubject');
pathsFcn        = ft_getopt(cfg, 'pathsFcn');
artefacts       = ft_getopt(cfg, 'artefacts');

if nargin < 2
    if isempty(pathsFcn)
        error('please add options function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end
    
    disp(currSubject)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data ,artefactdef] = bv_check4data(subjectFolderPath, inputStr, artefactdefStr);
    
end

if not(iscell(artefacts))
    artefacts = {artefacts};
end

if length(data.trial) ~= size(artefactdef.sampleinfo,1)
    cfg = [];
    cfg.length = (range(artefactdef.sampleinfo(1,:))+1) ./ data.fsample;
    cfg.overlap = 0;
    evalc('data = ft_redefinetrial(cfg, data);');
    
    if not(sum(sum(data.sampleinfo == artefactdef.sampleinfo)) == numel(data.sampleinfo))
        error('data cannot be cut into same samples as artefactdefenition given')
    end
end

fprintf(['\t adding the following artefacts to artefactdef: ' ...
    repmat('%s ', 1, length(artefacts)) ' ... '], artefacts{:})
for i = 1:length(data.trial)
    for j = 1:length(artefacts)
        switch artefacts{j}
            case 'abs'
                artefactdef.abs.levels(:,i) = max(abs(data.trial{i}),[],2);
            case 'range'
                artefactdef.range.levels(:,i) = max(data.trial{i}, [], 2) - min(data.trial{i}, [], 2);
            case 'variance'
                artefactdef.variance.levels(:,i) = std(data.trial{i}, [], 2).^2;
            case 'kurtosis'
                artefactdef.kurtosis.levels(:,i) = kurtosis(data.trial{i}, [], 2);
            case 'flatline'
                artefactdef.flatline.levels(:,i) = 1./(abs(max(data.trial{i},[],2) - min(data.trial{i},[],2)));
            otherwise
                error('Unknown artefact condition: %s', artefacts{j})
        end
    end
end
fprintf('done! \n')

if strcmpi(saveData, 'yes')
       
    bv_saveData(subjectdata, artefactdef, artefactdefStr);
    
end