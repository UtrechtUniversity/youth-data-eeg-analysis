function bv_plotmst(W, chans)

if nargin < 2
    chans = [];
end

D = weight_conversion(W, 'lengths');

mst = graphminspantree(sparse(D), 'method', 'Kruskal');
% mst = mst + rot90(flipud(mst), -1);

if nargin < 2
    G = graph(mst,'lower');
else 
    G = graph(mst, chans,'lower');
end

plot(G)