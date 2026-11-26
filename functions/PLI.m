function [conn_matrix] = PLI(data,dim)
% Computes the phase lag index (PLI) connectivity matrix.
%
% The PLI (Stam, Nolte & Daffertshofer, 2007, Hum Brain Mapp 28(11):
% 1178-1193) measures the asymmetry of the distribution of instantaneous
% phase differences between two signals: PLI = |mean(sign(sin(dphi)))|. It
% is 0 for no (or purely zero-lag) coupling and 1 for perfect non-zero-lag
% phase locking. The instantaneous phase comes from the analytic signal
% (hilbert), so the input should already be band-pass filtered to the
% frequency band of interest.
%
% Epochs are handled independently, so the output holds one connectivity
% matrix per epoch; averaging over epochs is left to the caller. The
% diagonal of each matrix is 0. A channel containing NaNs yields NaN
% entries for every pair it is part of.
%
% hilbert comes from the Signal Processing Toolbox.
%
% Args:
%     data (numeric or cell array): Time series. Either a 2-D matrix
%         (single epoch) or 3-D matrix with epochs concatenated in the third
%         dimension, or a cell array with one 2-D matrix per epoch. For
%         ``dim = 0`` the matrices are time x channels, for ``dim = 1``
%         channels x time (the layout of a FieldTrip ``data.trial`` cell).
%     dim (numeric, optional): ``0``: columns are channels; ``1``: rows are
%         channels. Defaults to ``0``.
%
% Returns:
%     conn_matrix (numeric or cell array): chan x chan x epoch matrix when
%         ``data`` is numeric, or a cell array (same size as ``data``) of
%         chan x chan matrices when ``data`` is a cell array.
%
% Example:
%     ```matlab
%     % FieldTrip data with channels x time per trial
%     plis = PLI(dataCut.trial, 1);   % cell array, one chan x chan per trial
%     ```

if nargin<2; dim = 0; end

if ~iscell(data) && ~isnumeric(data)
    error('PLI: data must be a numeric array or a cell array of matrices, got %s', class(data))
end
if ~isscalar(dim) || ~ismember(dim, [0 1])
    error('PLI: dim must be 0 (columns are channels) or 1 (rows are channels)')
end

if iscell(data)
    conn_matrix = cell(size(data));
    for n = 1:length(data)
        conn_matrix{n} = PLIsingletrial(data{n},dim);
    end
else
    if dim
        conn_matrix = zeros(size(data,1),size(data,1),size(data,3));
    else
        conn_matrix = zeros(size(data,2),size(data,2),size(data,3));
    end
    for n = 1:size(data,3)
        conn_matrix(:,:,n) = PLIsingletrial(data(:,:,n),dim);
    end
end

%% helper function
function [conn_matrix] = PLIsingletrial(data,dim)
% PLI matrix (chan x chan) of one epoch, see PLI.

if dim; data = data'; end

num_chans = size(data,2);

hilsig = hilbert(data);
hilsig = angle(hilsig);

conn_matrix = zeros(num_chans);
for i = 1:num_chans
    for j = 1:num_chans
        if ~(i==j) && conn_matrix(i,j)==0
            phasediff = hilsig(:,i)-hilsig(:,j);
            phasediff = sin(phasediff);
            phasediff(phasediff>0) = 1;
            phasediff(phasediff<0) = -1;
            PLIval = abs(mean(phasediff));
            conn_matrix(i,j) = PLIval;
            conn_matrix(j,i) = PLIval;
        end
    end
end
