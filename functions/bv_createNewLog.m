function bv_createNewLog(logIn)
% Creates (or overwrites) a log.txt file with a FILEINFO header.
%
% Writes a centered ``FILEINFO`` banner followed by ``created`` and
% ``lastModified`` timestamps (both set to the current time) and
% ``lastAnalysis`` (the name of the function that called this one, taken
% from the call stack). Note: ``lastModified`` is only ever written here
% at creation time; nothing else in the pipeline currently updates it.
%
% Args:
%     logIn (str): Full path to the log file to create. Overwrites the
%         file if it already exists.

analysisTitle = 'FILEINFO';
titleLength = 30;
analysisTitle = strcat(repmat('*', 1, ...
    ceil((titleLength-length(analysisTitle))/2)), analysisTitle, ...
    repmat('*',1,floor((titleLength-length(analysisTitle))/2)));

lastCalled = dbstack('-completenames',1);
if isempty(lastCalled)
    callerName = 'command line';
else
    callerName = lastCalled(1).name;
end

fidlog = fopen(logIn, 'w');
fprintf(fidlog, '%s\n', analysisTitle);
fprintf(fidlog, '%s, %s\n', 'created', datetime);
fprintf(fidlog, '%s, %s\n', 'lastModified', datetime);
fprintf(fidlog, '%s, %s\n', 'lastAnalysis', callerName);
fclose(fidlog);

