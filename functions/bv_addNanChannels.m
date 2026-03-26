function dataOut = bv_addNanChannels(dataIn, chansIn, origchans)

missedchans = find(not(ismember(origchans,chansIn)));
sz = size(dataIn);
dim2add = find(sz == length(chansIn));
sz(dim2add) = sz(dim2add) + numel(missedchans);
dataOut = NaN(sz);
idxexpr = { repmat(':', 1, dim2add - 1), setdiff(1:length(origchans),missedchans), repmat(':', 1, ndims(dataIn)-dim2add) };
dataOut(idxexpr{:}) = dataIn;
