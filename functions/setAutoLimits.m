function setAutoLimits(ax, lims)
% finds the correct limits for a connectivity matrix based on the highest and
% lowest values in the matrix (so ignores the diagonal)
%
% usage:
%   setAutoLimits(ax)

if nargin < 1
    try
        ax = gca; %current figure handle
    catch
        error('current figure not found, please give handle ax as input')
    end
end

if nargin == 2
    set(ax, 'CLim', lims);
    return
end


dataObjs = get(ax, 'Children'); % handle to low-level graphics objects in axes

data = dataObjs.CData;
minlim = min(data(data~=0));
maxlim = max(data(data~=0));

if minlim == maxlim || (isnan(minlim) || isnan(maxlim))
    minlim = 0;
    maxlim = 1;
end

set(ax, 'CLim', [minlim maxlim]);
