function [conn_matrix] = PLI(data,dim)
% Written by - 04-27-2010
% Last modified: 05-10-2010 (fixed phase difference range correction)
% Modified: 04-28-2010 (added multi-epoch support and header)
%
% This function generates the PLI[1] connectivity matrix (conn_matrix).
% Inputs:
%   data = variable containing the timeseries data. This variable may
%          take form of a 2- or 3-dimensional matrix where columns are
%          sensors(but see dim) and epochs are concatenated in the third
%          dimension. Alternatively, input can be a cell array
%          containing epochs (2-D matrix, where columns are sensors)
%   dim  = optional flag to signal whether rows or columns represent
%          sensors. 0 [default] means columns are sensors, 1 means rows
%          are.

if nargin<2; dim = 0; end

if iscell(data)
    conn_matrix = cell(size(data));
    for n = 1:length(data)
        conn_matrix{n} = PLIsingletrial(data{n},dim);
    end
else
    if dim;
        conn_matrix = zeros(size(data,1),size(data,1),size(data,3));
    else conn_matrix = zeros(size(data,2),size(data,2),size(data,3));
    end
    for n = 1:size(data,3)
        conn_matrix(:,:,n) = PLIsingletrial(data(:,:,n),dim);
    end
end


function [conn_matrix] = PLIsingletrial(data,dim)

if dim; data = data'; end

num_chans = size(data,2);

hilsig = hilbert(data);
hilsig = angle(hilsig);

conn_matrix = zeros(num_chans);
counter = 0;
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
