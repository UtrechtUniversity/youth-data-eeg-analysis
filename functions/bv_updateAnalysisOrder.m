function analysisOrder = bv_updateAnalysisOrder(analysisOrder, cfgInput)

analysisSplit = strsplit(analysisOrder, '-');

if not(strcmpi(cfgInput.outputStr, 'compremoved'))
    switch cfgInput.inputStr
        case 'PREPROC'
            existingIndx = ismember(analysisSplit, {'res', 'filt', 'trial'});
            analysisSoFar = strjoin(analysisSplit(existingIndx), '-');
        otherwise
            existingIndx = find(ismember(analysisSplit, lower(cfgInput.inputStr)));
            if isempty(existingIndx)
                warning('previous analysis not found in analysisord')
            end
            analysisSoFar = strjoin(analysisSplit(1:existingIndx), '-');
    end
else
    existingIndx = find(ismember(analysisSplit, lower(cfgInput.compStr)));
    if isempty(existingIndx)
        warning('comp analysis not found in analysisord')
    end
    analysisSoFar = strjoin(analysisSplit(1:existingIndx), '-');
end

analysisOrder = [ analysisSoFar '-' lower(cfgInput.outputStr) ];





