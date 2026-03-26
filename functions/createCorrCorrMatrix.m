function [R, P] = createCorrCorrMatrix(Ws)
% usage:
%   [R, P] = createCorrCorrMatrix(Ws)
%
% creates a correlation matrix R with each cell representing all correlations
% between input connectivity matrices. Ws needs to have the following 3
% dimensions: node * node * nSubjects

R = zeros(size(Ws,3), size(Ws,3));
P = R;
for i = 1:size(Ws,3)
    currW1 = Ws(:, :, i);

    for j = 1:size(Ws,3)
        if i == j
            R(i,j) = 0;
            P(i,j) = NaN;
            continue;
        end
        currW2 = Ws(:, :, j);

        [currR, currP] = correlateMatrices(currW1, currW2);
        R(i,j) = currR;
        P(i,j) = currP;
    end
end
