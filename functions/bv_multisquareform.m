function Wsq = bv_multisquareform(Ws, tovector)

if nargin < 2
    tovector = true;
end

if tovector
    sz = size(Ws);
    if length(sz) > 3
        WsNew = reshape(Ws, [sz(1) sz(2) prod(sz(3:end))]);
    elseif length(sz)==2
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
