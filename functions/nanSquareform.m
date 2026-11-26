function Z = nanSquareform(Y)
% NaN-aware wrapper around MATLAB's squareform.
%
% Converts between a symmetric connectivity matrix and the vector of its
% unique edges (the upper triangle, in squareform order), without being
% constrained by the values on the diagonal:
%   - matrix -> vector: the diagonal is zeroed before vectorising, so the
%     returned edge vector contains only off-diagonal entries. NaNs on
%     off-diagonal edges (e.g. removed channels) are preserved. SQUAREFORM
%     itself would reject a matrix with a NaN diagonal.
%   - vector -> matrix: the reconstructed matrix gets NaNs on its diagonal.
%
% The direction is chosen from the input shape: a vector is converted to a
% matrix, a square matrix to a vector.
%
% Args:
%     Y (numeric): Either a symmetric chan x chan matrix, or a vector of
%         length chan*(chan-1)/2 holding its unique edges.
%
% Returns:
%     Z (numeric): The edge vector (1 x chan*(chan-1)/2) when ``Y`` is a
%         matrix, or the chan x chan matrix with a NaN diagonal when ``Y``
%         is a vector.
%
% Example:
%     ```matlab
%     W     = [NaN .2 .6; .2 NaN .4; .6 .4 NaN];
%     edges = nanSquareform(W);       % [.2 .6 .4]
%     Wback = nanSquareform(edges);   % same as W
%     ```

if ~isnumeric(Y) && ~islogical(Y)
    error('nanSquareform: input must be a numeric matrix or vector, got %s', class(Y))
end
if ~ismatrix(Y)
    error('nanSquareform: input must be a 2-D matrix or a vector, got %d dimensions', ndims(Y))
end

if isvector(Y)
    % a vector of N edges describes a matrix of n nodes with N = n(n-1)/2
    nNodes = (1 + sqrt(1 + 8*numel(Y))) / 2;
    if nNodes ~= round(nNodes)
        error(['nanSquareform: a vector of %d elements is not a valid edge vector ' ...
            '(length must be n*(n-1)/2, e.g. 1, 3, 6, 10, ...)'], numel(Y))
    end
    dir = 'tomatrix';
else
    if size(Y, 1) ~= size(Y, 2)
        error('nanSquareform: matrix input must be square, got %d x %d', size(Y, 1), size(Y, 2))
    end
    dir = 'tovector';
end

switch(dir)
    case 'tomatrix'
        Z = squareform(Y);
        ncols = size(Z,1);
        Z(1:ncols+1:end) = NaN;
    case 'tovector'
        ncols = size(Y,1);
        Y(1:ncols+1:end) = 0;
        Z = squareform(Y);
end
