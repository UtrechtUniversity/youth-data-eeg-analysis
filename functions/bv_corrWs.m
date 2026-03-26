function bv_corrWs(Ws1, Ws2)

n = size(Ws1,3);
m = size(Ws2,3);

for i = 1:n
    for j = 1:m
        R(i,j) = correlateMatrices(Ws1(:,:,i), Ws2(:,:,j));
    end
end
