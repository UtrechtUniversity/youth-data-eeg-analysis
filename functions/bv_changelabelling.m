function biplabels = bv_changelabelling(biplabels)

dict = {
    'Fp1-Cz', 'Fp1';
    'Fp1-C3', 'F3';
    'Fp1-T7', 'F7';
    'Fp2-Cz', 'Fp2';
    'Fp2-C4', 'F4';
    'Fp2-T8', 'F8';
    'T7-O1', 'P7';
    'C3-O1', 'P3';
    'Cz-O1', 'O1';
    'Cz-O2', 'O2';
    'C4-O2', 'P4';
    'T8-O2', 'P8';
    'C3-T7', 'T7';
    'Cz-C3', 'C3';
    'C4-Cz', 'C4';
    'T8-C4', 'T8'
    };
    
for i = 1:length(biplabels)
    if contains(biplabels{i}, 'EEG')
        biplabels{i} = biplabels{i}(5:end);
    end
    
    idx = ismember(dict(:,1), biplabels{i});
    if any(idx)
        biplabels{i} = dict{idx,2};
    else
        warning('biplabel not found in dict')
    end
    
end