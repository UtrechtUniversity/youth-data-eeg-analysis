function str = bv_calculateStrength(in)

if iscell(in)
    str = cellfun(@(x) squeeze(nanmean(nanmean(bv_multisquareform(x),1),3)), in, 'Un', 0);
    str = cat(1,str{:});
end
