function varargout = bv_splitData(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');
method      = ft_getopt(cfg, 'method');
amount      = ft_getopt(cfg, 'amount');
inputStr    = ft_getopt(cfg, 'inputStr');
saveData    = ft_getopt(cfg, 'saveData');

if nargin < 2
    disp(currSubject)
    eval(optionsFcn)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, dataOld] = bv_check4data(subjectFolderPath, inputStr);
end

switch method
    case 'interleaved'
        fprintf('\t cutting data interleaved in %1.0f pieces \n', amount)
        for i = 1:amount
            
            fprintf('\t\t selecting dataset %1.0f and saving ... ', i)
            cfg = [];
            cfg.trials = i:amount:length(dataOld.trial);
            evalc('varargout{i} = ft_selectdata(cfg, dataOld);');
            fprintf('done! \n')

            if strcmpi(saveData, 'yes')
                
                filename = [currSubject '_' inputStr num2str(i) '.mat'];
                subjectdata.PATHS.([inputStr  num2str(i)]) = [subjectdata.PATHS.SUBJECTDIR filesep filename];
                data = varargout{i};
                save(subjectdata.PATHS.([inputStr  num2str(i)]), 'data')
                fprintf('\t saving subjectdata to Subject.mat ...')
                save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'] ,'subjectdata')
                fprintf('done! \n')
                
                
                
            end
            
        end
    case 'split'
        fprintf('\t splitting data in %1.0f pieces \n', amount)
        for i = 1:amount
            
            startTrial  = floor((length(data.trial)/amount)*(i-1) + 1);
            endTrial    = floor((length(data.trial)/amount)*i);
            
            fprintf('\t\t selecting dataset %1.0f and saving ... ', i)
            cfg = [];
            cfg.trials = startTrial:endTrial;
            evalc('varargout{i} = ft_selectdata(cfg, dataOld);');
            fprintf('done! \n')

            if strcmpi(saveData, 'yes')
                filename = [currSubject '_' inputStr num2str(i) '.mat'];
                subjectdata.PATHS.([inputStr  num2str(i)]) = [subjectdata.PATHS.SUBJECTDIR filesep filename];
                data = varargout{i};
                save(subjectdata.PATHS.([inputStr  num2str(i)]), 'data')
                fprintf('\t saving subjectdata to Subject.mat ...')
                save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'] ,'subjectdata')
                fprintf('done! \n')
                
                
                
            end
            
        end
    otherwise
        error('unknown method')
end


