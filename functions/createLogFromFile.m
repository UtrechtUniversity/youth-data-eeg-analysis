function T1 = createLogFromFile(logcellEEG)

T1 = logcellEEG{1};
for i = 2:size(logcellEEG,2)
    T2 = logcellEEG{i};
    T2Missing = setdiff(T1.Properties.VariableNames, T2.Properties.VariableNames);
    T1Missing = setdiff(T2.Properties.VariableNames, T1.Properties.VariableNames);
    T2 = [T2 array2table(nan(height(T2), numel(T2Missing)), 'VariableNames', T2Missing)];
    T1 = [T1 array2table(nan(height(T1), numel(T1Missing)), 'VariableNames', T1Missing)];
    
    for colname = T2Missing
        if iscell(T1.(colname{1}))
            T2.(colname{1}) = cell(height(T2), 1);
        end
    end
    for colname = T1Missing
        if iscell(T2.(colname{1}))
            T1.(colname{1}) = cell(height(T1), 1);
        end
    end
    
    
    T1 = [T1; T2];
end

T1.wave(contains(T1.wave, '3y')) = {'3y'};
T1.wave(contains(T1.wave, '5m')) = {'5m'};
T1.wave(contains(T1.wave, '10m')) = {'10m'};

