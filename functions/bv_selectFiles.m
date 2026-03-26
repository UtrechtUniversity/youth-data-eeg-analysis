function [startFile, endFile] = bv_selectFiles(startFile, endFile, filenames)

if ischar(startFile)
    startFile = find(~cellfun(@isempty, strfind(filenames, startFile)));
    startFile = startFile(1);
end
if ischar(endFile)
    if strcmp(endFile, 'end')
        endFile = length(filenames);
    else
        endFile = find(~cellfun(@isempty, strfind(filenames, endFile)));
        endFile = endFile(end);
    end
end


