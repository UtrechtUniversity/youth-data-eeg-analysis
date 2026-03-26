function dataUse = bv_write2brainwave(cfg)

currSubject = ft_getopt(cfg, 'currSubject');
cleanedStr  = ft_getopt(cfg, 'cleanedStr');
inputStr    = ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr', '');
doFilter    = ft_getopt(cfg, 'filter');
freqband    = ft_getopt(cfg, 'freqband');

eval('setOptions')
eval('setPaths')

disp(currSubject)
subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
[~, dataInput] = bv_check4data(subjectFolderPath, inputStr);

filename = [PATHS.BRAINWAVE filesep currSubject '_' outputStr '_bw.txt'];

if strcmpi(doFilter, 'yes')
    if isempty(freqband)
        error('No cfg.freqband given')
    end
    
    switch freqband
        case 'delta'
            hpfreq = 1;
            lpfreq = 3;
        case 'theta'
            hpfreq = 3;
            lpfreq = 6;
        case 'alpha1'
            hpfreq = 6;
            lpfreq = 9;
        case 'alpha2'
            hpfreq = 9;
            lpfreq = 12;
        case 'beta'
            hpfreq = 12;
            lpfreq = 25;
        case 'gamma'
            hpfreq = 25;
            lpfreq = 45;
        otherwise
            error('unknown freqband given')
    end
    
    cfg = [];
    cfg.hpfreq = hpfreq;
    cfg.lpfreq = lpfreq;
    
    dataFilt = bv_filterEEGdata(cfg, dataInput);
    
    filename = [PATHS.BRAINWAVE filesep currSubject '_' freqband '_' outputStr '_bw.txt'];
    
end

if ~isempty(cleanedStr)
    [~, dataCleaned] = bv_check4data(subjectFolderPath, cleanedStr);
    cfg = [];
    cfg.trl = [dataCleaned.sampleinfo, zeros(length(dataCleaned.trialinfo),1), ...
        dataCleaned.trialinfo];
    evalc('dataUse = ft_redefinetrial(cfg, dataFilt);');
elseif strcmpi(doFilter, 'yes')
    dataUse = dataFilt;
else
    dataUse = dataInput;
end

fprintf('\t saving %s ...', filename)
trialdata = [dataUse.trial{:}];
formatSpec = [repmat('%f \t ', 1, size(trialdata,1)) '\n'];
fid = fopen(filename, 'w');
fprintf(fid, formatSpec, trialdata);
fclose( 'all' );
fprintf('done! \n')