function [ ICC_r, ICC_CI ] = bv_scanwiseICC( Ws, nboot )
% calculates the ICC_r of global connectivity between two sessions.
%
% usages:
%   [ ICC_r ] = bv_scanwiseICC( Ws )
%   [ ICC_r, ICC_CI ] = bv_scanwiseICC( Ws, nboot )
%
% Input:
%   Ws: connectivity matrices of two sessions with following dimensions:
%         nNodes x nNodes x nSubjects x nSessions
%   nboot (optional): calculates the 95% confidence interval of output ICC_r by
%         using matlab bootstrp function with nboot being amount of datasamples
%         drawn
%
% Output:
%   ICC_r: ICC reliability value of global connectivity ('1-k')
%   ICC_CI: 95% confidence interval if nboot input given
%
% See also ICC, NANSQUAREFORM, BOOTSTRP

if nargin < 2
  doboot = false;
else
  doboot = true;
end

sz = size(Ws);
if sz(end) ~= 2
    error('Scan session dimension not last in Ws. Please redo your Ws dimensions')
end

if sz(1) ~= sz(2)
    error('Your Ws do not consist of square connectivity matrices')
end

if length(sz) > 4
    error('More than 4 dimensions found. Unknown dimension ... ')
end

scAvg = zeros(size(Ws,3), size(Ws,4));
for iWs = 1:size(Ws,3)
    for jWs = 1:size(Ws,4)
        scAvg(iWs, jWs) = nanmean(nansquareform(Ws(:,:,iWs, jWs)));
    end
end

ICC_r = ICC(scAvg, '1-k');

if doboot
    bootstat = bootstrp(nboot,@(x) ICC(x, '1-k'), scAvg);
    ICC_CI = prctile(bootstat, [2.5, 97.5])  
end
