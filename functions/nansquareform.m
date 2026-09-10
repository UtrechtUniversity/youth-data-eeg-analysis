function Z = nansquareform(Y)
% NaN-aware wrapper around MATLAB's squareform.
%
% usage:
%   [ Z ] = nansquareform(Y)
%
% Converts between a connectivity matrix and its vectorised upper triangle
% without being constrained by the values on the diagonal:
%   - matrix -> vector: the diagonal is zeroed before vectorising, so the
%     returned edge vector contains only off-diagonal entries (NaNs on
%     off-diagonal edges, e.g. removed channels, are preserved).
%   - vector -> matrix: the reconstructed matrix gets NaNs on its diagonal.
%
% See also SQUAREFORM

if isvector(Y)
    dir = 'tomatrix';
else
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
