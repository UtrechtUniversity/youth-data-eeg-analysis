function bv_normDirW(A)

M = size(A,1);
N = size(A,2);
idx = eye(M,N);
A(~idx) = (A(~idx) - min(A(~idx))) / (max(A(~idx)) - min(A(~idx)));