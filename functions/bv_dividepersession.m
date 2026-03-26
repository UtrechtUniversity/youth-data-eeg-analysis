function [output, names] = bv_dividepersession(snames, data)

subjectNames = cellfun(@(v) v(1:5), snames, 'Un', 0);
uniqueSubjectNames = unique(subjectNames);
occurrenceSubjectNames = cellfun(@(x) ...
    sum(ismember(subjectNames,x)),uniqueSubjectNames,'Un',0);

twoSessionIndex = [occurrenceSubjectNames{:}]==2;
uniqueTwoSessions = uniqueSubjectNames(twoSessionIndex);
twoSessionSnamesIndex = contains(snames, uniqueTwoSessions);

session1Index = twoSessionSnamesIndex .* contains(snames, 'A');
session2Index = twoSessionSnamesIndex .* contains(snames, 'B');

names = cat(2, snames(logical(session1Index))', snames(logical(session2Index))');
output = cat(2, data(logical(session1Index))', data(logical(session2Index))');
