function [var2mplusOut, uniqueSubjects] = bv_prepareForMPlus(inTable, groupingVarName, var2mplusIn, nanval, zscoring)
%  usage:
%   [ outVar ] = bv_prepareForMPlus( inVar, groupingVar )

if nargin < 4
    nanval = NaN;
end
if nargin < 5
    zscoring = false;
end


if iscell(inTable.(var2mplusIn))
    doCell = true;
else
    doCell = false;
end

if any(ismember(size(inTable.(var2mplusIn)), 1))
    dm = 1;
else
    dm = ndims(inTable.(var2mplusIn));
end

[g_indx, g_name] = findgroups(inTable.(groupingVarName));
uniqueSubjects = unique(inTable.pseudo, 'stable');
if doCell
    var2mplusOut = cell(length(uniqueSubjects),length(g_name));
else
    if dm==1
        var2mplusOut = nan(length(uniqueSubjects),length(g_name));
    elseif dm==2
        var2mplusOut = nan(length(uniqueSubjects), size(inTable.(var2mplusIn), 2),length(g_name));
    elseif dm==3
        var2mplusOut = nan(length(uniqueSubjects), size(inTable.(var2mplusIn), 2), size(inTable.(var2mplusIn), 2),length(g_name));

    else
        error('Variable to split has too many dimensions')
    end
end

for i = 1:length(uniqueSubjects)
    currSubject = uniqueSubjects{i};
    subjectIndx = find(ismember(inTable.pseudo, currSubject));
    sessionIndxPerSubject = ismember(g_name, inTable.(groupingVarName)(subjectIndx));

    if doCell
        if length(subjectIndx) > length(g_name)
            [var2mplusOut{i,:}] = deal('');
        elseif length(subjectIndx) ~= sum(sessionIndxPerSubject)
            [var2mplusOut{i,:}] = deal('');
        else
            for j = 1:length(subjectIndx)
                var2mplusOut{i, ...
                    ismember(g_name,inTable.(groupingVarName)(subjectIndx(j)))} = ...
                    inTable.(var2mplusIn){subjectIndx(j)};
            end
        end
    else
        if ndims(inTable.(var2mplusIn)) < 3
            if length(subjectIndx) > length(g_name)
                var2mplusOut(i,:) = NaN;
            elseif length(subjectIndx) ~= sum(sessionIndxPerSubject)
                var2mplusOut(i,:) = NaN;
            else
                for j = 1:length(subjectIndx)
                    var2mplusOut(i, ...
                        ismember(g_name,inTable.(groupingVarName)(subjectIndx(j)))) = ...
                        inTable.(var2mplusIn)(subjectIndx(j));
                end
            end
        elseif ndims(inTable.(var2mplusIn)) == 3
            if length(subjectIndx) > length(g_name)
                var2mplusOut(i,:,:) = NaN;
            elseif length(subjectIndx) ~= sum(sessionIndxPerSubject)
                var2mplusOut(i,:,:) = NaN;
            else
                for j = 1:length(subjectIndx)
                    var2mplusOut(i, :, :,...
                        find(ismember(g_name,inTable.(groupingVarName)(subjectIndx(j))))) = ...
                        squeeze(inTable.(var2mplusIn)(subjectIndx(j),:,:));
                end
            end

        else
            error('Variable to split has too many dimensions')
        end
    end
end
if zscoring
    var2mplusOut = bv_nanZScore(var2mplusOut);
end
if ~iscell(var2mplusOut)
    var2mplusOut(isnan(var2mplusOut)) = nanval;
end


