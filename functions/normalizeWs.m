function Wsnrm = normalizeWs(Ws, range)

if nargin<2 || isempty(range)
    range = [0 1];
end

m = size(Ws,3);
n = size(Ws,4);
Wsnrm = zeros(size(Ws));
for i = 1:n
    for j = 1:m
        W = squeeze(Ws(:,:,j,i));
        
        diagTmp = diag(W);
        if sum(diagTmp) ~= 0
            ncols = size(W,2);
            W(1:ncols+1:end) = 0;
        end
        sqW = nansquareform(W);
        
        a = (range(2)-range(1))/(max(sqW(:))-min(sqW(:)));
        b = range(2) - a * max(sqW(:));
        sqWnrm = a * sqW + b;
        
        Wnrm = squareform(sqWnrm);
        Wnrm(logical(eye(length(W)))) = diagTmp;
        Wsnrm(:,:,j,i) = Wnrm;
        
    end
end