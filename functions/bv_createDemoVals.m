function Tout = bv_createDemoVals(T, attritionVar, groupVar)

[gGrouped, nmGroupedAtt, nmGroupedGroup] = findgroups(T.(attritionVar), T.(groupVar));
N_grp = histcounts(gGrouped);
[gTotal, nmIfAtt, nmGroup] = findgroups(cellfun(@isempty, T.(attritionVar)), T.(groupVar));
N_total = histcounts(gTotal);

unGroupnm = unique(nmGroup);
unAttnm = unique(nmGroupedAtt);
Tout = table();
for i = 1:length(unGroupnm)
    indx = find(ismember(nmGroup, unGroupnm{i}) & nmIfAtt==0);
    Tout.Session{i} = nmGroup{indx};
    Tout.N(i) = sum(N_total(ismember(nmGroup, unGroupnm{i})));
    Tout.N_att(i) = N_total(indx);
    Tout.(['%_att'])(i) = round(Tout.N_att(i) ./ Tout.N(i) * 100,1);
    
    for j = 1:length(unAttnm)
        indx2 = find(ismember(nmGroupedGroup, unGroupnm{i}) & ...
            ismember(nmGroupedAtt, unAttnm{j}));
        if isempty(indx2)
            continue
        end
        Tout.(['N_' unAttnm{j}])(i) = N_grp(indx2);
        Tout.(['%_' unAttnm{j}])(i) = round(Tout.(['N_' unAttnm{j}])(i) ./ Tout.N(i) * 100,1);
    end
end
    
