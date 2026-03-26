function deg = bv_visualizeDegreeDifference(Ws, grp, labels)

if length(size(Ws)) ~= 3 || size(Ws,1) ~= size(Ws,2)
    error('Ws input expected to have dim(nChans x nChans x nSubjects)')
end
if length(grp) ~= size(Ws,3)
     error('Grp length does not agree with Ws dim(3)')
end
if length(labels) ~= size(Ws,1)
    error('Labels length does not agree with Ws dim(1,2)')
end
[grpCode, grpName] = findgroups(grp);
deg = splitapply(@mean, squeeze(sum(Ws,2))', grpCode);
diffDeg = diff(deg);
topoplotWrapper(diffDeg, labels);
if iscell(grpName)
    title([grpName{2} ' - ' grpName{1}])
else
    title([num2str(grpName(2)) ' - ' num2str(grpName(1))])
end