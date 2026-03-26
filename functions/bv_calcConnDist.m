function [dist,x] = bv_calcConnDist(Ws, steps)

if nargin < 2
    steps = 0.01;
end

maxW = max(Ws(:));
minW = min(Ws(:));
x = minW:steps:maxW;

dist = zeros(length(x), size(Ws,3));
for i = 1:size(Ws,3)
    [dist(:,i)] = hist(squareform(Ws(:,:,i)), x);
end
    