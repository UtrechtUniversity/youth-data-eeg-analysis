function Wsq = bv_multisquareform(Ws, tovector)
% Apply (nan)squareform across a stack of connectivity matrices.
%
% usage:
%   Wsq = bv_multisquareform(Ws, tovector)
%
% inputs:
%   Ws        with tovector=true (default): an array of connectivity
%             matrices with dim (chan x chan x ...). Any trailing
%             dimensions (e.g. epoch, freq) are collapsed, each chan x chan
%             slice is vectorised with nansquareform, and the result is
%             reshaped back to (... x nEdges).
%             With tovector=false: a stack of edge vectors (nSlices x nEdges)
%             that are expanded back into square matrices (chan x chan x nSlices).
%   tovector  logical, direction of the transform (default: true).
%
% See also NANSQUAREFORM, SQUAREFORM

if nargin < 2
    tovector = true;
end

if tovector
    sz = size(Ws);
    if length(sz) > 3
        WsNew = reshape(Ws, [sz(1) sz(2) prod(sz(3:end))]);
    elseif length(sz) == 2
        Wsq = nansquareform(Ws);
        return;
    else
        WsNew = Ws;
    end

    Wsq = zeros(size(WsNew,3), length(nansquareform(WsNew(:,:,1))));
    for i = 1:size(WsNew,3)
        Wsq(i,:) = nansquareform(WsNew(:,:,i));
    end

    if length(sz) > 3
        Wsq = reshape(Wsq, [sz(3:end), size(Wsq,2)]);
    end

else
    for i = 1:size(Ws, 1)
        Wsq(:,:,i) = squareform(Ws(i,:));
    end
end
