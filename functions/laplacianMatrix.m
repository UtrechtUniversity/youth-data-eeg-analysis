function L = laplacianMatrix(A);

I = eye(size(A));
D = diag(degrees_und(A));

L = I - D^-1*A;