function [startSubject, endSubject, subjectFolderNames] = getSubjectRange(startSubject, endSubject)
% Resolves a start/end subject (by name or index) into a usable range.
%
% Args:
%     startSubject (str or int): Subject folder name (or substring
%         uniquely matching one) or 1-based index of the first subject.
%     endSubject (str or int): Subject folder name (or substring uniquely
%         matching one), 1-based index of the last subject, or ``'end'``
%         for the last subject folder found.
%
% Returns:
%     startSubject (int): 1-based index of the first subject.
%     endSubject (int): 1-based index of the last subject.
%     subjectFolderNames (cell array of str): Names of every (non-removed)
%         subject folder under ``PATHS.SUBJECTS``, in the order returned
%         by ``dir`` - the same order ``startSubject``/``endSubject``
%         index into.
%
% Example:
%     ```matlab
%     [startSubject, endSubject, subjectFolderNames] = getSubjectRange(1, 'end');
%     ```

eval('setPaths')

subjectFolders = dir(PATHS.SUBJECTS);
subjectFolders = subjectFolders([subjectFolders.isdir] & ~ismember({subjectFolders.name}, {'.', '..'}));
subjectFolders = subjectFolders(~strcmp(fullfile(PATHS.SUBJECTS, {subjectFolders.name}), PATHS.REMOVED));
subjectFolderNames = {subjectFolders.name};

if ischar(startSubject)
    startSubject = resolveSubjectIndex(startSubject, subjectFolderNames);
end
if ischar(endSubject)
    if strcmp(endSubject, 'end')
        endSubject = length(subjectFolderNames);
    else
        endSubject = resolveSubjectIndex(endSubject, subjectFolderNames);
    end
end

end


function idx = resolveSubjectIndex(name, subjectFolderNames)
% Resolves a subject folder name (or substring) to a unique 1-based index.
matches = find(contains(subjectFolderNames, name));
if isempty(matches)
    error('getSubjectRange:notFound', ...
        'No subject folder found matching ''%s''.', name)
elseif ~isscalar(matches)
    error('getSubjectRange:ambiguous', ...
        '''%s'' matches multiple subject folders (%s); provide a more specific name.', ...
        name, strjoin(subjectFolderNames(matches), ', '))
end
idx = matches;
end
