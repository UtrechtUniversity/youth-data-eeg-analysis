function [SWPs, delta_Cs, delta_Ls] = gr_calculateSmallworldPropensityWs(As)
% Function to calculate small-worldness index on multiple adjecency
% matrices.
%
%  usage:
%   [SWPs, delta_Cs, delta_Ls] = gr_calculateSmallworldPropensityWs(As)
%
% with the following necessary inputs:
%  As:          adjacency matrix with dim(chan x chan x subject)
%  edgeType:    'weighted', 'binary', 'mst'
%
% and the following options inputs:
%  randWs:      randomized As based on input As with dim (chan x chan x subject x nrandomizations)
%  Cs:          earlier calculated clustering coefficients for all As
%  CPL:         earlier calculated characteristic path lengths for all As
%
% If options inputs are not given, they will be calculated in the function,
% which makes the function take longer.


sz = size(As);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nwsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nwsz);
end

m = size(As, 3);

SWPs = zeros(m, 1);
delta_Cs = zeros(m, 1);
delta_Ls = zeros(m, 1);

counter = 0;
for i = 1:m
    currW = As(:,:,i);
    if any(any(isnan(currW)))
        SWPs(i) = NaN;
        delta_Cs(i) = NaN;
        delta_Ls(i) = NaN;
        counter = counter + 1;
        continue
    end
    
    currW = gr_normalizeW(currW);
    [SWPs(i),delta_Cs(i),delta_Ls(i)] = small_world_propensity(currW, 'O');
        
end

sel = SWPs<0 |SWPs >1;
SWPs(sel) = NaN;
delta_Cs(sel) = NaN;
delta_Ls(sel) = NaN;

if ndims > 3
    SWPs = reshape(SWPs, extraDims);
    delta_Cs = reshape(delta_Cs, extraDims);
    delta_Ls = reshape(delta_Ls, extraDims);
end

