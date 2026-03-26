function subjectdatasummary = bv_addLog2Subjectsummary(subjectdatasummary)

eval('setPaths')
logsEEG = dir([PATHS.FILES filesep '*EEG*.xlsx']);
logsEEG = logsEEG(not(contains({logsEEG.name}, '~')));

for i = 1:length(logsEEG)
    path2log = [logsEEG(i).folder filesep (logsEEG(i).name)];
    logcellEEG{i} = bv_log2Table(path2log);
end
T_EEG = createLogFromFile(logcellEEG);

logsGEN = dir([PATHS.FILES filesep '*GEN*.xlsx']);
if ~isempty(logsGEN)
    logsGEN = logsGEN(not(contains({logsGEN.name}, '~')));
    
    for i = 1:length(logsGEN)
        path2log = [logsGEN(i).folder filesep (logsGEN(i).name)];
        logscellGEN{i} = bv_log2Table(path2log);
    end
    T_GEN = createLogFromFile(logscellGEN);
    
    
    T_all = joinbasedonfirst(T_EEG, T_GEN, {'pseudo', 'wave'});
    
else
    T_all = T_EEG;
end

switch class(subjectdatasummary)
    case 'table'
        subjectdatasummary = joinbasedonfirst(subjectdatasummary, T_all, {'pseudo', 'wave'});
    case 'struct'
        T_subjectdatasummary = struct2table(subjectdatasummary);
        T_subjectdatasummary = joinbasedonfirst(T_subjectdatasummary, T_all, {'pseudo', 'wave'});
        subjectdatasummary = table2struct(T_subjectdatasummary);
end


function T_join = joinbasedonfirst(T1, T2, Keys)

T1_sel = T1{:,contains(T1.Properties.VariableNames, Keys)};
T2_sel = T2{:,contains(T2.Properties.VariableNames, Keys)};

for i = 1:height(T1)
    T2Indx = find(all(ismember(T2_sel, T1_sel(i,:)),2));        
    
    if length(T2Indx) == 1
        T_join(i,:) = innerjoin(T1(i,:), T2(T2Indx,:), 'Keys', Keys);
    else
        emptyTable = T2(1,:);
        emptyTable.pseudo = T1_sel(i,1);
        emptyTable.wave = T1_sel(i,2);
        emptyTable(:,3:end) = {''};
        
        T_join(i,:) = innerjoin(T1(i,:), emptyTable, 'Keys', Keys);
    end
end











