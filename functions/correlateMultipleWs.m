function [R, P] = correlateMultipleWs(Ws1, Ws2)
% usage:
%   [R, P] = correlateMultipleWs(Ws1, Ws2)
%
% calculates the correlation between two groups of connectivity matrices using
% a pearson R correlation and the function correlateMatrices. Input Ws1 and Ws2
% have to have equal dimensions
%
% See also CORRELATEMATRICES

if nargin < 2
    error('Please add in two sets of correlations matrices')
end

if sum(size(Ws1) == size(Ws2)) ~= length(size(Ws1))
    error('size Ws1 (%s) does not equal size Ws2 (%s)', num2str(size(Ws1)), num2str(size(Ws2)))
end

for iW = 1:size(Ws1,3);
    currW1 = Ws1(:,:,iW);
    currW2 = Ws2(:,:,iW);

    [currR, currP] = correlateMatrices(currW1, currW2);
    R(iW) = currR;
    P(iW) = currP;
end
