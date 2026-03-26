function T_out = bv_log2Table(path2log)

opts = detectImportOptions(path2log);
opts = setvartype(opts, 'char');
T_log = readtable(path2log, opts);
T_log(ismember(T_log.pseudo, 'B'),:) = []; % removing log problems (empty subjects)
T_log(cellfun(@isempty, T_log.submitdate),:) = [];
varLib = {'YBEEGCHLABJGENEQ001', 'roomNumber'; 
    'YBEEGCHLABJGENEQ002', 'Temp'; 
    'YBEEGCHLABJGENEQ003', 'PrimaryAssistant';
    'YBEEGCHLABJGENEQ004', 'Illumination'; 
    'YBEEGCHLABJGENEQ005', 'ElectrodeCode';
    'YBEEGCHLABJGENEQ005_other_', 'ElectrodeCodeOther';
    'YBEEGCHLABJGENEQ006', 'HeadCircum';
    'YBEEGCHLABJGENEQ008', 'Headshape';
    'YBEEGCHLABJGENEQ009', 'PrimaryAssistant';
    'YBEEGCHLABJGENEQ010', 'SecondaryAssistant';
    'YBEEGCHLABJGENEQ007_1_', 'FirstTask';
    'YBEEGCHLABJGENEQ007_2_', 'SecondTask';
    'YBEEGCHLABJGENEQ007_3_', 'ThirdTask';
    'YBEEGCHLABJFAHOQ001', 'Facehouse_Completed';
    'YBEEGCHLABJFAHOQ002', 'Facehouse_NotCompleteCause';
    'YBEEGCHLABJFAHOQ003', 'Facehouse_Cap'
    'YBEEGCHLABJFAHOQ004', 'Facehouse_CapPoorCause';
    'YBEEGCHLABJFAHOQ006', 'Facehouse_ElectrodeLeftEye';
    'YBEEGCHLABJFAHOQ008', 'Facehouse_Position';
    'YBEEGCHLABJFAHOQ009', 'Facehouse_Towel';
    'YBEEGCHLABJFAHOQ010', 'Facehouse_ParentWithChild';
    'YBEEGCHLABJFAHOQ011_CRYING_', 'Facehouse_Crying';
    'YBEEGCHLABJFAHOQ011_LOOK_', 'Facehouse_Looking';
    'YBEEGCHLABJFAHOQ011_MOVE_', 'Facehouse_Moving';
    'YBEEGCHLABJFAHOQ012', 'Facehouse_Quality';
    'YBEEGCHLABJCOHEQ001', 'Coherence_Completed';
    'YBEEGCHLABJCOHEQ002', 'Coherence_NotCompleteCause';
    'YBEEGCHLABJCOHEQ003', 'Coherence_Cap'
    'YBEEGCHLABJCOHEQ004', 'Coherence_CapPoorCause';
    'YBEEGCHLABJCOHEQ006', 'Coherence_ElectrodeLeftEye';
    'YBEEGCHLABJCOHEQ008', 'Coherence_Position';
    'YBEEGCHLABJCOHEQ009', 'Coherence_Towel';
    'YBEEGCHLABJCOHEQ010', 'Coherence_ParentWithChild';
    'YBEEGCHLABJCOHEQ011_CRYING_', 'Coherence_Crying';
    'YBEEGCHLABJCOHEQ011_LOOK_', 'Coherence_Looking';
    'YBEEGCHLABJCOHEQ011_MOVE_', 'Coherence_Moving';
    'YBEEGCHLABJCOHEQ012', 'Coherence_Quality';
    'YBEEGCHLABJFAEMQ001', 'Faceemo_Completed';
    'YBEEGCHLABJFAEMQ002', 'Faceemo_NotCompleteCause';
    'YBEEGCHLABJFAEMQ003', 'Faceemo_Cap'
    'YBEEGCHLABJFAEMQ004', 'Faceemo_CapPoorCause';
    'YBEEGCHLABJFAEMQ006', 'Faceemo_ElectrodeLeftEye';
    'YBEEGCHLABJFAEMQ008', 'Faceemo_Position';
    'YBEEGCHLABJFAEMQ009', 'Faceemo_Towel';
    'YBEEGCHLABJFAEMQ010', 'Faceemo_ParentWithChild';
    'YBEEGCHLABJFAEMQ011_CRYING_', 'Faceemo_Crying';
    'YBEEGCHLABJFAEMQ011_LOOK_', 'Faceemo_Looking';
    'YBEEGCHLABJFAEMQ011_MOVE_', 'Faceemo_Moving';
    'YBEEGCHLABJFAEMQ012', 'Faceemo_Quality';
    'YBGENGELABJGENEQ002', 'NormalDay'
    'YBGENGELABJGENEQ002_other_', 'WhyNotNormalDay'
    
    
    'YBEEGCHL03YGENEQ001', 'roomNumber'; 
    'YBEEGCHL03YGENEQ002', 'Temp'; 
    'YBEEGCHL03YGENEQ004', 'Illumination'; 
    'YBEEGCHL03YGENEQ005', 'ElectrodeCode'; 
    'YBEEGCHL03YGENEQ005_other_', 'ElectrodeCodeOther'; 
    'YBEEGCHL03YGENEQ006', 'HeadCircum';
    'YBEEGCHL03YGENEQ008', 'PrimaryAssistant';
    'YBEEGCHL03YGENEQ009', 'SecondaryAssistant';
    'YBEEGCHL03YTAORQ001_1_', 'FirstTask';
    'YBEEGCHL03YTAORQ001_2_', 'SecondTask';
    'YBEEGCHL03YTAORQ001_3_', 'ThirdTask';
    'YBEEGCHL03YFAHOQ001', 'Facehouse_Completed';
    'YBEEGCHL03YFAHOQ002', 'Facehouse_NotCompleteCause';
    'YBEEGCHL03YFAHOQ003', 'Facehouse_Cap'
    'YBEEGCHL03YFAHOQ004', 'Facehouse_CapPoorCause';
    'YBEEGCHL03YFAHOQ006', 'Facehouse_ElectrodeLeftEye';
    'YBEEGCHL03YFAHOQ008', 'Facehouse_Position';
    'YBEEGCHL03YFAHOQ009', 'Facehouse_Towel';
    'YBEEGCHL03YFAHOQ010', 'Facehouse_ParentWithChild';
    'YBEEGCHL03YFAHOQ011_CRYING_', 'Facehouse_Crying';
    'YBEEGCHL03YFAHOQ011_LOOK_', 'Facehouse_Looking';
    'YBEEGCHL03YFAHOQ011_MOVE_', 'Facehouse_Moving';
    'YBEEGCHL03YFAHOQ012', 'Facehouse_Quality';
    'YBEEGCHL03YCOHEQ001', 'Coherence_Completed';
    'YBEEGCHL03YCOHEQ002', 'Coherence_NotCompleteCause';
    'YBEEGCHL03YCOHEQ003', 'Coherence_Cap'
    'YBEEGCHL03YCOHEQ004', 'Coherence_CapPoorCause';
    'YBEEGCHL03YCOHEQ006', 'Coherence_ElectrodeLeftEye';
    'YBEEGCHL03YCOHEQ008', 'Coherence_Position';
    'YBEEGCHL03YCOHEQ009', 'Coherence_Towel';
    'YBEEGCHL03YCOHEQ010', 'Coherence_ParentWithChild';
    'YBEEGCHL03YCOHEQ011_CRYING_', 'Coherence_Crying';
    'YBEEGCHL03YCOHEQ011_LOOK_', 'Coherence_Looking';
    'YBEEGCHL03YCOHEQ011_MOVE_', 'Coherence_Moving';
    'YBEEGCHL03YCOHEQ012', 'Coherence_Quality';
    'YBEEGCHL03YFAEMQ001', 'Faceemo_Completed';
    'YBEEGCHL03YFAEMQ002', 'Faceemo_NotCompleteCause';
    'YBEEGCHL03YFAEMQ003', 'Faceemo_Cap'
    'YBEEGCHL03YFAEMQ004', 'Faceemo_CapPoorCause';
    'YBEEGCHL03YFAEMQ006', 'Faceemo_ElectrodeLeftEye';
    'YBEEGCHL03YFAEMQ008', 'Faceemo_Position';
    'YBEEGCHL03YFAEMQ009', 'Faceemo_Towel';
    'YBEEGCHL03YFAEMQ010', 'Faceemo_ParentWithChild';
    'YBEEGCHL03YFAEMQ011_CRYING_', 'Faceemo_Crying';
    'YBEEGCHL03YFAEMQ011_LOOK_', 'Faceemo_Looking';
    'YBEEGCHL03YFAEMQ011_MOVE_', 'Faceemo_Moving';
    'YBEEGCHL03YFAEMQ012', 'Faceemo_Quality'
    'YBGENGEL03YGENEQ002', 'NormalDay'
    'YBGENGEL03YGENEQ002_other_', 'WhyNotNormalDay'};

taskNoABJ = sum(contains(T_log.Properties.VariableNames, 'YBGENGELABJGENEQ003'));
tmpCellABJ = [strcat('YBGENGELABJGENEQ003_', sprintfc('%d',1:taskNoABJ), '_')', ...
    strcat('TASK', sprintfc('%d',1:taskNoABJ))'];
taskNo03Y = sum(contains(T_log.Properties.VariableNames, 'YBGENGEL03YGENEQ003'));
tmpCell03Y = [strcat('YBGENGEL03YGENEQ003_', sprintfc('%d',1:taskNo03Y), '_')', ...
    strcat('TASK', sprintfc('%d',1:taskNo03Y))'];

varLib = cat(1,varLib, tmpCellABJ, tmpCell03Y);

codeVarsIndx = contains(T_log.Properties.VariableNames, {'YBEEG', 'YBGEN'});
T_out = table();
T_out.pseudo = T_log.pseudo;
T_out.wave = T_log.wave;
T_out.submitdate = T_log.submitdate;

for i = find(codeVarsIndx)
    currVar = T_log.Properties.VariableNames{i};
    libIndx = ismember(varLib(:,1), currVar);
    if sum(libIndx) ~= 0
        T_out.(varLib{libIndx,2}) = T_log.(currVar);
    end
end
    
    