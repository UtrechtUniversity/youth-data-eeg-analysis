function Z = nansquareform(Y)
% usage:
%   [ Z ] = nansquareform(Y)
%
% wrapper of regular squareform matlab function, but creates a connectivity
% matrix with NaNs on the diagonal or reads in a matrix with NaNs (or zero's
% for that matter). No constrained by values found on diagonal. Check for
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
