function struct = bv_addNansToResultsStruct(struct, layout)

if nargin < 2
    warning('no layout given, biosemi32.lay used')
    layout = 'biosemi32.lay';
end

if ~isfield(struct, 'label')
    error('no label fieldname in given struct')
end

cfg = [];
cfg.layout = layout;
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
cfg.feedback = 'no';
evalc('ft_prepare_layout(cfg);');

missingChans = cellfun(@(x) find(not(contains(lay.label, x))), {struct.label}, 'Un',0)
missingChansIndx = find(not(cellfun(@isempty, missingChans)));

for i = 1:length(missingChansIndx)
    curMissingChannel = missingChans{missingChansIndx(i)};
    curSubject = powerresults(missingChansIndx(i)).name;
    nChans = length(powerresults(missingChansIndx(i)).label);
    disp(curSubject)
    fprintf(['\t misses channel ' repmat('%s, ', 1, length(curMissingChannel)) '... \n' ], lay.label{curMissingChannel})

    fnames = fieldnames(struct);
    fnames = fnames(not(contains(fnames, {'name', 'label'})));
    for j = 1:length(fnames)
        currVar = struct(missingChansIndx(i)).(fnames{j});
        if isstruct(currVar)
            fnamesdeep = fieldnames(currVar);
            for k = 1:length(fnamesdeep)
                currDeepVar = currVar.(fnamesdeep{k});
                dim2change = find(size(currDeepVar) == nChans);
                
                
                
            
end
        