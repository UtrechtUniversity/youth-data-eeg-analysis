function bv_resampleRaws(str, resampleFs)

allDataFiles = dir([pwd filesep '*' str '*']);
dataNames = {allDataFiles.name};

[startSubject, endSubject] = bv_selectFiles('10967A_ruweEEG.bdf', 'end', dataNames);

for iData = startSubject:endSubject
    currFile = dataNames{iData};
    disp(currFile)
    
    [ ~, origFilename, dataType] = fileparts(currFile);
    
    switch dataType
        case '.bdf'
            headerfile = currFile;
            dataset = currFile;
            
        case '.eeg'
            error('.eeg is not implemented yet')
            
        otherwise
            error(sprintf('unknown datatype %s', dataType))
    end
    
    fprintf('\t loading data ... ') 
    cfg = [];
    cfg.headerfile  = headerfile;
    cfg.dataset     = dataset;
    cfg.trialfun    = 'trialfun_resample'
    cfg = ft_definetrial(cfg)
    
    evalc('data = ft_preprocessing(cfg);');
    fprintf('done! \n');        
    
    origHdr = ft_read_header(headerfile);
    byte1 = 2^8 - 1;
    data.trial{1}(end,:) = (256-bitand(abs(data.trial{1}(end,:)), byte1));
    rsTriggers = data.trial{1}(end,1:(origHdr.Fs/resampleFs):end);
   
    fprintf('\t resampling to %s Hz ... ', num2str(resampleFs))
    cfg = [];
    cfg.resamplefs  = resampleFs;
    cfg.demean      = 'yes';
    evalc('data = ft_resampledata(cfg, data);');
    fprintf('done! \n')
    
    data.trial{1}(end,:) = rsTriggers;
    
    filename = [origFilename '_' 'resampled'];
    fprintf('\t saving %s ... ', filename)
    save(filename, 'data')
    fprintf('done! \n')
    
end


