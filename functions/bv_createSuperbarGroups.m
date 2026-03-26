function m = bv_createSuperbarGroups(dat, grpvector, grplabels)
addpath('~/MatlabToolboxes/superbar/superbar/')

m = splitapply(@nanmedian, dat, grpvector);
se = splitapply(@(x) 2.*nanstd(x)./sum(~isnan(x)), dat, ...
    grpvector);

% figure;
superbar(m, 'E', se)

if nargin == 3
    set(gca, 'XTick', 1:length(grplabels), 'XTickLabels', grplabels)
end