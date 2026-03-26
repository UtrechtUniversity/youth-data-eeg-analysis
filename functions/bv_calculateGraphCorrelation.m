function R = bv_calculateGraphCorrelation(g1, g2)

equalDims = isequal(size(g1), size(g2)) || (isvector(g1) && isvector(g2) && numel(g1) == numel(g2));

if ~equalDims
    error('graph metrics to be correlated not equal dimensions')
end
 

R = zeros(1,size(g1,2));
for i = 1:size(g1,2)
    R(i) = corr(g1(:,i), g2(:,i), 'rows', 'pairwise');
end