function bv_splitWsPerFreq(cfg, resultsName)

freqLabels  = ft_getopt(cfg, 'freqLabels', {'delta', 'theta', 'alpha1', 'alpha2',  'beta', 'gamma'});
freqRanges  = ft_getopt(cfg, 'freqRanges', {[0.1 3], [3 6], [6 9], [9 12], [12 25], [25 45]});

% if length(freqLabels) ~= length(freqRanges)
%     error('freqRange and freqLabels not equal')
% end
if nargin < 2
    error('No input for (path to) results file')
end
if nargin < 1
    error('No configuration file added')
end

try
    [PATHS.RESULTS, filename, ~] = fileparts(resultsName);
    fprintf('loading %s ... ', filename)
    load(resultsName)
    fprintf('done! \n')
catch
    error('%s not found', resultsName)
end

if isempty(PATHS.RESULTS)
    PATHS.RESULTS = pwd;
end

origWs = Ws;
origDims = dims;

if iscell(freq)
    freqLabels = freq;
    freqRanges = freqRng;
    
    for iFreq = 1:length(freqLabels);
        cLabel = freqLabels{iFreq};
        cRange = freqRanges{iFreq};
        
        freqband = cLabel;
        
        Ws = squeeze(origWs(:,:,iFreq,:,:));
        
        dims = strsplit(origDims, '_');
        dims(3) = [];
        Wsdims = strjoin(dims, '-');
        
        output = [filename '_' cLabel '.mat'];
        
        fprintf('saving Ws for frequency %s ... ', cLabel)
        save([PATHS.RESULTS filesep output], 'Ws' ,'chans', 'Wsdims', 'freqband', 'subjects')
        fprintf('done! \n')
    end
else
    for iFreq = 1:length(freqRanges)
        cLabel = freqLabels{iFreq};
        cRange = freqRanges{iFreq};
        
        freqband = cLabel;
        
        [~, startIndx] = min(abs(freq - cRange(1)));
        [~, endIndx] = min(abs(freq - cRange(2)));
        
        Ws = squeeze(nanmean(origWs(:,:,startIndx:endIndx,:,:),3));
        
        dims = strsplit(origDims, '_');
        dims(3) = [];
        Wsdims = strjoin(dims, '_');
        
        output = [filename '_' cLabel '.mat'];
        
        fprintf('saving Ws for frequency %s ... ', cLabel)
        save([PATHS.RESULTS filesep output], 'Ws' ,'chans', 'Wsdims', 'freqband', 'subjects')
        fprintf('done! \n')
    end
end
    
    
