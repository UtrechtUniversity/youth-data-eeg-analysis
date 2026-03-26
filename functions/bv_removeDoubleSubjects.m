function out = bv_removeDoubleSubjects(in)

subjNames = strcat(in.pseudo, '_', in.week);

[d, id] = findgroups(subjNames);
counts = histc(d, 1:length(id));

doubleSubjects = id(counts>1);
for i = 1:length(doubleSubjects)
    indx = find(contains(in.subjectName, doubleSubjects{i}));
    bool = max(cellfun(@length, in(indx,:).trialinfo))==...
        cellfun(@length, in(indx,:).trialinfo);
    if sum(bool) > 1
        bool = eye(size(bool)).*bool>0;
    end
        
    incorrIndx = indx(~bool);
    in(incorrIndx,:) = [];
end
   
out = in;
