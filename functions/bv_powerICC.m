tmp = load('power.mat');
ftmp = fieldnames(tmp);
if length(ftmp) > 1
    error('unknown results file format')
else
    results = tmp.(ftmp{1});
end

sesNames = fieldnames(results);
sesFields = fnames(not(cellfun(@isempty, strfind(sesNames, 'session'))));
freqFields = fieldnames(results.(sesFields{1}));
typeFields = fieldnames(results.(sesFields{1}).(freqFields{1}));

for iFreq = 1:length(freqFields)
    cFreq = freqFields{iFreq};
    
    for iType = 1:length(typeFields)
        cType = typeFields{iType};
        
        clear vals
        for iSes = 1:length(sesFields)
            cSes = sesFields{iSes};
            
            vals(:,iSes) = [results.(cSes).(cFreq).(cType)];
        end
        
        vals = vals(not(any(isnan(vals),2)),:);
        
        ICCresults.(cFreq).(cType) = ICC(vals, '1-k');
        correlation = corr(vals, 'rows', 'pairwise');
        corrResults.(cFreq).(cType) = correlation(2);
    end
     
end
