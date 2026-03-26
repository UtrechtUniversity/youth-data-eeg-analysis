function R = bv_corrSesConnectivity(Ws)

nSes = size(Ws,4);

if nSes ~= 2
    error('%1.0f sessions found, can only correlate 2 sessions', nSes)
end

Ws1 = Ws(:,:,:,1);
Ws2 = Ws(:,:,:,2);

R = correlateMultipleWs(Ws1, Ws2);