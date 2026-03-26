function [ out ] = bv_setDiag( M, value )
% set the diagonal of multiple matrices to a certain value
%
% usage:
%   [ M_out ] = bv_setDiag( M, value )
%
% input:
%   M: 3-dimensional matrix
%   value: Value to which the diagonal of all matrices along the 3rd dimension
%         M will be set.
%
% output:
%   M_out: M, but with the diagonals of all matrices along the third dimension
%         set to inputted value.
%
[m,n,p]=size(M);
idx=find(speye(m,n));
xx=reshape(M,m*n,p);
xx(idx,:) = value;

out = reshape(xx, m,n,p);
