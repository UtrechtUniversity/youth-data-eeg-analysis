function Wnrm = gr_normalizeW(W)
% Min-max normalises the edge weights of a symmetric connectivity matrix.
%
% Rescales the unique edge weights (upper triangle) linearly onto [0, 1], so
% the weakest edge becomes 0 and the strongest becomes 1. A matrix whose
% edges are already all 0 or 1 (binary) is returned unchanged. Used by the
% network-metric functions before converting weights to connection lengths.
%
% Args:
%     W (numeric): Symmetric chan x chan connectivity matrix with a zero
%         diagonal.
%
% Returns:
%     Wnrm (numeric): Matrix of the same size as ``W`` with edge weights
%         rescaled to [0, 1]; the diagonal is zero. Returned as-is if ``W``
%         is binary.
%
% Example:
%     ```matlab
%     W    = [0 .2 .6; .2 0 .4; .6 .4 0];
%     Wnrm = gr_normalizeW(W);   % edges become 0, 0.5 and 1
%     ```

Wsq = nansquareform(W);

if ~all(ismember(unique(Wsq, 'sorted'), [0 1]))
    Wsqnrm = (Wsq - min(Wsq)) / (max(Wsq) - min(Wsq));
    Wnrm = squareform(Wsqnrm);
else
    Wnrm = W;
end
