function T = bv_addResults2SubjectSummary(T, inputStr)
eval('setPaths')

if isstruct(T)
    T = struct2table(T);
end

for i = 1:height(T)
    lng = printPercDone(height(T), i);
    if isfield(T.PATHS{i}, upper(inputStr))
        if exist(T.PATHS{i}.(upper(inputStr)), 'file')
            output = load(T.PATHS{i}.(upper(inputStr)));
            fields = fieldnames(output);
            T.(inputStr){i} = output.(fields{1});
        end
    end
    fprintf(repmat('\b', 1, lng))
end
