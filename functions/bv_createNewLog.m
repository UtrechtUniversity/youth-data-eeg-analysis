function bv_createNewLog(logIn)

analysisTitle = 'FILEINFO';
titleLength = 30;
analysisTitle = strcat(repmat('*', 1, ...
    ceil((titleLength-length(analysisTitle))/2)), analysisTitle, ...
    repmat('*',1,floor((titleLength-length(analysisTitle))/2)));

lastCalled = dbstack('-completenames',1);

fidlog = fopen(logIn, 'w');
fprintf(fidlog, '%s\n', analysisTitle);
fprintf(fidlog, '%s, %s\n', 'created', datetime);
fprintf(fidlog, '%s, %s\n', 'lastModified', datetime);
fprintf(fidlog, '%s, %s\n', 'lastAnalysis', lastCalled(1).name);
fclose(fidlog);



