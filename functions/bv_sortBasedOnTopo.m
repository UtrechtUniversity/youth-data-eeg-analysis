function [ data ] = bv_sortBasedOnTopo(data)
% sortBasedOnTopo uses FT_PREPARE_LAYOUT to sort the data channels based on
% actual place on the brain sorted from front to back and left to right
%
% Use as:
%   [ data ] = bv_sortBasedOnTopo( data )
%
% In which,
%   data:   is a datastructure from fieldtrip
%
% See also FT_PREPARE_LAYOUT

fprintf(' \t sorting channels ... ' )
% order channels based on location
cfg = [];
cfg.channel  = data.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipcomnt  = 'yes';
cfg.skipscale  = 'yes';
evalc('lay = ft_prepare_layout(cfg);'); % get standard channel sort, use evalc to prevent additional messages on command line

% sort current dataset based on standard
[~, indxSort] = ismember(lay.label, data.label);
indxSort = indxSort(indxSort>0);
data.label = data.label(indxSort);
data.trial = cellfun(@(x) x(indxSort,:), data.trial, 'Un', 0);
fprintf('done! \n')