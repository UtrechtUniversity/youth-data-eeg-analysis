function Wnrm = normalizeW(W, range)

if nargin<2
    range = [0 1];
end

diagTmp = diag(W);
if sum(diagTmp) ~= 0
    ncols = size(W,2);
    W(1:ncols+1:end) = 0;
end
sqW = squareform(W);

a = (range(2)-range(1))/(max(sqW(:))-min(sqW(:)));
b = range(2) - a * max(sqW(:));
sqWnrm = a * sqW + b;

Wnrm = squareform(sqWnrm);
Wnrm(logical(eye(length(W)))) = diagTmp;
