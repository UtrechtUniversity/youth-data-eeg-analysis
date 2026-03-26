function powerdata = bv_calculatePowerMetrics(cfg, data)

inputStr 	= ft_getopt(cfg, 'inputStr');
currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');
freqBands   = ft_getopt(cfg, 'freqBands', {[0.1 3], [3 6], [6 9]});
freqLabels  = ft_getopt(cfg, 'freqLabels', {'delta', 'theta', 'alpha'});
saveData    = ft_getopt(cfg, 'saveData', 'no');
outputStr   = ft_getopt(cfg, 'outputStr', 'power');

if length(freqBands) ~= length(freqLabels)
    error('cfg.freqBands and cfg.freqLabels differ in length')
end

if nargin < 2
    disp(currSubject)
    
    eval(pathsFcn)
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    try
        [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    catch
        error('inputStr data not found')
    end
else
    fprintf('Own input \n')
end

% check for missing channels
cfg = [];
cfg.layout = 'biosemi32.lay';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
cfg.feedback = 'no';
evalc('lay = ft_prepare_layout(cfg);');

missingChannelIndx = find(not(ismember(lay.label, data.label)));
if ~isempty(missingChannelIndx)
    missingChans = lay.label(missingChannelIndx);
    fprintf('\t missing channels found \n ')
    fprintf(['\t \t adding nans in the place of ' ...
        repmat('%s, ', 1, length(missingChannelIndx)) '\n'], missingChans{:})
    cfg = [];
    cfg.missingchannel = lay.label(missingChannelIndx);
    cfg.method = 'nan';
    evalc('data = ft_channelrepair(cfg, data);');
end
[data] = bv_sortBasedOnTopo(data);

fprintf('\t calculating frequency spectrum ...')
evalc('[freq, fd] = bvLL_frequencyanalysis(data, minmax([freqBands{:}]));');
fprintf('done! \n')

for i = 1:length(freqBands)
    currFreq = freqBands{i};
    currFreqlabel = freqLabels{i};
    idx = fd.freq >= currFreq(1) & fd.freq <= currFreq(2);
    y = squeeze(nanmean(fd.powspctrm(:,:,idx)));
    x = fd.freq(idx);
    
    for j = 1:size(y,1)
        powerdata.(currFreqlabel).AreaUnderCurve(j) = trapz(x,smooth(y(j,:)));
        
        [pks, locs] = findpeaks(smooth(y(j,:)),x);
        if isempty(pks)
            powerdata.(currFreqlabel).pks(j) = NaN;
            powerdata.(currFreqlabel).locs(j) = NaN;
        else
            [~,imax] = max(pks);
            powerdata.(currFreqlabel).pks(j) = pks(imax);
            powerdata.(currFreqlabel).locs(j) = locs(imax);
        end
    end
end

powerdata.label = fd.label;
powerdata.pow = fd.powspctrm;
powerdata.freq = fd.freq;

if strcmpi(saveData, 'yes')
    bv_saveData(subjectdata, powerdata, outputStr)
end
