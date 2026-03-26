function [R, P] = correlateMatrices(W1, W2)
% usage:
%   [R, P] = correlateMatrices(W1, W2)
%
% Calculates the pearson's R correlation between two connectivity matrices(W1 &
% W2). Matrices have to have equal dimensions. NaNs will be ignored.

if numel(W1) ~= numel(W2)
    error('different matrix sizes')
end
ncols = size(W1, 2);
W1(1:ncols+1:end) = 0;
W2(1:ncols+1:end) = 0;

if (sum(isnan(squareform(W1))) == numel(squareform(W1))) || (sum(isnan(squareform(W2))) == numel(squareform(W2)))
    R = NaN;
    P = NaN;
else
    [R, P] = corr(squareform(W1)', squareform(W2)','rows', 'pairwise');
end
