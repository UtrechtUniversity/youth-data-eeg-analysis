function Wnrm = gr_normalizeW(W)
% Function to normalize adjacency matrices
%
% See also SQUAREFORM

Wsq = nansquareform(W);

if ~all(ismember(unique(Wsq, 'sorted'), [0 1]))
    Wsqnrm = Wsq;
    Wsqnrm = (Wsqnrm - min(Wsqnrm)) / ...
        (max(Wsqnrm) - min(Wsqnrm));
    Wnrm = squareform(Wsqnrm);
else
    Wnrm = W;
end



