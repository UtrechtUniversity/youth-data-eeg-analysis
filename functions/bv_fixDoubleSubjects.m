function T_out = bv_fixDoubleSubjects(T)

subjName = strcat(T.pseudo, '_', T.wave);
[unSubj, ~, J] = unique(subjName);
occ = histc(J, 1:numel(unSubj));

multSessions = unSubj(occ>1);
T_out = T;

for i = 1:length(multSessions)
    c_mult = multSessions{i};
    selT = T(ismember(subjName, c_mult),:);
    diffDate = diff(datetime(selT.testdate, 'InputFormat', 'dd-MM-yy'));
    if diffDate == 0
        [~,earlyIndex] = min(datetime(selT.testtime, 'InputFormat', 'HH:mm:ss'));
        T_out(contains(T_out.subjectName, selT.subjectName),:) = [];
        selT = selT(earlyIndex,:);
        T_out = [T_out; selT];
    else
        fprintf('%s is measured on two different days, removing both sessions\n', c_mult)
        T_out(contains(T.subjectName, selT.subjectName),:) = [];
    end
    T_out = sortrows(T_out, {'subjectName'});
end



