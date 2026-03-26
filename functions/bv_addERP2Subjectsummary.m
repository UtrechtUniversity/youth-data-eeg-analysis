function T = bv_addERP2Subjectsummary(T, ERPstr)
eval('setPaths')

inputStruct = isstruct(T);

if inputStruct
    T = struct2table(T);
end

for i = 1:height(T)
    currSubject = T.subjectName{i};
    disp(currSubject)
    try
        [subjectdata, ERPdata] = bv_check4data([PATHS.SUBJECTS filesep currSubject], ERPstr);
    catch
        fprintf('\t no ERP data found \n')
        continue
    end
    T.(['ERP_' ERPstr]){i} = ERPdata.avg;
    T.(['ERPtime_' ERPstr]){i} = ERPdata.time;
end

if inputStruct
    T = table2struct(T);
end