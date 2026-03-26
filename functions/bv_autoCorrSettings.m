function bv_autoCorrSettings(ax, labels)
% creates a nicely formatted connectivity matrix with colorbar. Uses
% setAutoLimits.m
%
% usage:
%   bv_autoCorrSettings(ax, labels)
%
% INPUTS:
%   ax: axishandle to be beautified
%   labels: labels for ticks (xticks and yticks identical)
%
% See also, SETAUTOLIMITS

if nargin < 2
    labels = [];
end

setAutoLimits(ax);
colorbar
axis square

if ~isempty(labels)
    set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels);
    set(gca, 'YTick', 1:length(labels), 'YTickLabel', labels);
end
