function [startSubject, endSubject, subjectFolderNames] = bv_getSubjectRange(startSubject, endSubject)
% helper function to give you the indices of the start subject and end
% subject for your analysis. 
%
% Usage:
%   [ startSubject , endSubject, subjectFolderNames ] = bv_getSubjectRange( startSubject, endSubject )
%
% Input:
%   startSubject        Can be name of folder or index
%   endSubject          Can be name of folder, index, or the string 'end'
%
% Output:
%   startSubject        Index of starting subject
%   endSubject          Index of end subject
%   subjectFolderNames  { cell } with strings with all folder names

eval('setPaths')
eval('setOptions')

subjectFolders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectFolderNames = {subjectFolders.name};

if ischar(startSubject)
    startSubject = find(contains(subjectFolderNames, startSubject));
end
if ischar(endSubject)
    if strcmp(endSubject, 'end')
        endSubject = length(subjectFolderNames);
    else
        endSubject = find(contains(subjectFolderNames, endSubject));
    end
end

