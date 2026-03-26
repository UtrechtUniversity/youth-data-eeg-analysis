function T = bv_calculateNetworksCharacteristics(T, spctrmvar, chars)

if strcmpi(chars, 'all')
    chars = {'SWP', 'SW', 'strength'};
end

if range(cellfun(@(x) size(x,1), T.(spctrmvar))) ~=0 || ...
        range(cellfun(@(x) size(x,2), T.(spctrmvar))) ~=0
    error('Subjects do not have the same number of channels in their connectivity matrix')
end

spctrm = T.(spctrmvar);
kepttrials = range(cellfun(@(x) size(x,3), spctrm))~=0;

if kepttrials
    updateWaitbar = waitbarParfor(length(spctrm)*length(chars), "Calculate characteristics...");
    strength = zeros(length(spctrm), length(T.freq{1}));
    SWP = zeros(length(spctrm), length(T.freq{1}));
    SW = zeros(length(spctrm), length(T.freq{1}));
    for i = 1:length(spctrm)
        if ismember('strength', chars)
            strength(i,:) = nanmean(nanmean(bv_multisquareform(spctrm{i}),1),3);
            updateWaitbar()
        end
        if ismember('SWP', chars)
            sz = size(spctrm{i})
            SWP(i,:) = ...
                nanmean(reshape(gr_calculateSmallworldPropensityWs(...
                reshape(spctrm{i}, [sz(1) sz(2) prod(sz(3:end))])), [sz(3:4)]));
            updateWaitbar()
        end
        if ismember('SW', chars)
            sz = size(spctrm{i})
            SW(i,:) = ...
                nanmean(reshape(gr_calculateSmallWorldnessHumphries(...
                reshape(spctrm{i}, [sz(1) sz(2) prod(sz(3:end))])), [sz(3:4)]));
            updateWaitbar()
        end
        
    end
else
    updateWaitbar = waitbarParfor(length(spctrm)*length(chars), "Calculate characteristics...");
    strength = zeros(length(spctrm), length(T.freq{1}));
    SWP = zeros(length(spctrm), length(T.freq{1}));
    SW = zeros(length(spctrm), length(T.freq{1}));
    for i = 1:length(spctrm)
        if ismember('strength', chars)
            strength(i,:) = nanmean(bv_multisquareform(spctrm{i}),2);
            updateWaitbar()
        end
        if ismember('SWP', chars)
            SWP(i,:) = gr_calculateSmallworldPropensityWs(spctrm{i});
            updateWaitbar()
        end
        if ismember('SW', chars)
            SW(i,:) = gr_calculateSmallWorldnessHumphries(spctrm{i});
            updateWaitbar()
        end
    end
end


if ismember('strength', chars)
    if kepttrials
        str = cellfun(@(x) squeeze(nanmean(nanmean(bv_multisquareform(x),1),3)), spctrm, 'Un', 0);
        T.strength = cat(1,str{:});
    else
        maxDim = length(spctrm(out{1}));
        T.strength = nanmean(bv_multisquareform(cat(maxDim+1, spctrm{:})),maxDim)';   
    end
end
if ismember('SW', chars)
    T.SW = SW;
end
if ismember('SWP', chars)
    T.SWP = SWP;
end

        