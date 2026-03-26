function r_unit = bv_unitwiseICC(Ws, pc)
% calculates the ICC of all individual edges in a connectivity matrix over
% sessions
%
% usages:
%   [ ICC_unit ] = bv_unitwiseICC( Ws )
%   [ ICC_unit ] = bv_unitwiseICC( Ws, pc )
%
% Input:
%   Ws: undirectional connectivity matrices with the following dimensions:
%         nNodes x nNodes x nSubjects x nSessions
%   pc (optional): percentage threshold to only use the strongest percentage of
%         connections (ranges from 0-100)
%
% Output:
%   ICC_unit: ICC for all individual edges in connectivity matrix with
%         size(1, (nNodes * (nNodes-1)) ./ 2)
% See also, ICC
%

sz = size(Ws);
if sz(end) ~= 2
    error('Scan session dimension not last in Ws. Please permute your Ws dimensions')
end

if sz(1) ~= sz(2)
    error('Your Ws do not consist of square connectivity matrices')
end

if length(sz) > 4
    error('More than 4 dimensions found. Unknown dimension ... ')
end

avg = squeeze(nanmean(nanmean(Ws, 3),4));

if nargin < 2
    pc = 0;
end

sqAvg = squareform(avg);
Y = prctile(sqAvg, pc);
thr = sqAvg>=Y;

n = size(Ws,3);
sqWs1 = zeros(n, sum(thr));
sqWs2 = zeros(n, sum(thr));
for i = 1:n
    currSq1 = squareform(Ws(:,:,i,1));
    currSq2 = squareform(Ws(:,:,i,2));

    sqWs1(i,:) = currSq1(thr);
    sqWs2(i,:) = currSq2(thr);
end
sqWs = cat(3,sqWs1,sqWs2);

m = size(sqWs,2);
r_unit = zeros(1,m);
corr_unit = zeros(1,m);
for i = 1:m
    curr = squeeze(sqWs(:,i,:));
    curr = curr(~any(isnan(curr),2),:);
    curr = curr(~any(isinf(curr),2),:);
    r_unit(i) = ICC(curr, '1-k');
    corr_unit(i) = corr(curr(:,1), curr(:,2));
end
