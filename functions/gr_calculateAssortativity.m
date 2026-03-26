function [rs] = gr_calculateAssortativity(As, flag)
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
rs = zeros(m, 1);
counter = 0;
for i = 1:m
    currW = As(:,:,i);
    if any(any(isnan(currW)))
        rs(i) = NaN;
        counter = counter + 1;
        continue
    end
    
    currW = gr_normalizeW(currW);
    rs(i) = assortativity_wei(currW,flag);
        
end

if ndims > 3
    rs = reshape(rs, extraDims);
end

