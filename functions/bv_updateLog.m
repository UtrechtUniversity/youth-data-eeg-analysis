function strct = bv_updateLog(logIn, logstrct)
% function used to update log.txt file in the root analysis folder

if exist(logIn, 'file')
    cd(fileparts(which(logIn)))
    
    lastCalled = dbstack('-completenames',1);
    strct = bv_log2struct(logIn);
    strct.lastModified = datestr(datetime);
    strct.lastAnalysis = lastCalled(1).name;
    for fn = fieldnames(logstrct)'
        strct.(fn{1}) = logstrct.(fn{1});
    end
    
    fidold = fopen(logIn, 'r');
    fidnew = fopen('tmplog.txt','w');
    
    while 1
        line = fgetl(fidold);
        
        if line==-1
            break
        end
        
        if strcmp(line(1), '*')
            fprintf(fidnew,'%s\n', line);
        else
            fnames = fieldnames(strct);
            presentIndx = find(contains(fnames,strsplit(line, ', ')));
            if ~isempty(presentIndx)
                fprintf(fidnew, '%s, %s\n', fnames{presentIndx}, strct.(fnames{presentIndx}));
                strct = rmfield(strct, fnames{presentIndx});
            end
        end
    end
    
    fclose(fidold); fclose(fidnew);
    
    
    if ~isempty(fieldnames(strct))
        nameCoding = {'bv_createSubjectFolders', ...
            'SUBJECT FOLDER CREATION', 'bv_preprocResample', 'PREPROCESSING'};
        
        for i = 1:length(nameCoding)
            if strfind(lastCalled(1).name, nameCoding{i})
                analysisTitle = nameCoding{i+1};
                break
            end
            analysisTitle = lastCalled(1).name;
        end
        
        titleLength = 30;
        analysisTitle = strcat(repmat('*', 1, ...
            ceil((titleLength-length(analysisTitle))/2)), analysisTitle, ...
            repmat('*',1,floor((titleLength-length(analysisTitle))/2)));
        
        fidappend = fopen('tmplog.txt','a');
        fprintf(fidappend, '%s\n', analysisTitle);
        fnames = fieldnames(strct);
        for i = 1:length(fnames)
            fprintf(fidappend, '%s, %s\n', fnames{i}, num2str(strct.(fnames{i})));
        end
    end
    
    delete(logIn)
    movefile('tmplog.txt', logIn)
        
    strct = bv_log2struct(logIn);
else
    bv_createNewLog(logIn)
end







