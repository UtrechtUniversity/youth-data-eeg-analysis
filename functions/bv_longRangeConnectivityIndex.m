function lrConnectivityNrm = bv_longRangeConnectivityIndex(Ws, labels, shortRangeMask)

if nargin < 3
    cfg = [];
    cfg.layout = 'EEG1010';
    cfg.channel = labels;
    cfg.feedback = 'no';
    cfg.skipcomnt = 'yes';
    cfg.skipscale = 'yes';
    evalc('lay = ft_prepare_layout(cfg);');
    
    cfg = [];
    cfg.method          = 'distance';
    cfg.neighbourdist   = 0.4;
    cfg.template        = 'EEG1010';
    cfg.layout          = lay;
    cfg.channel         = 'all';
    cfg.feedback        = 'no';
    cfg.skipcomnt       = 'yes';
    cfg.skipscale       = 'yes';
    evalc('neighbours = ft_prepare_neighbours(cfg);');
    
    tmp = cellfun(@(x) ismember(labels, x), {neighbours.neighblabel}, 'UniformOutput', false);
    shortRangeMask = cat(2, tmp{:});
end

longRangeMask = not(shortRangeMask);
longRangeMask(1:length(longRangeMask)+1:end) = 0;
sqMask = squareform(longRangeMask);
Wssq = bv_multisquareform(Ws);

lrConnectivity = sum(Wssq(:,find(sqMask)),2);
allConnectivity = sum(Wssq,2);
lrConnectivityNrm  = lrConnectivity ./ allConnectivity;