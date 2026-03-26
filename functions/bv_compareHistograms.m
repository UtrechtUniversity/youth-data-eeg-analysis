function bv_compareHistograms(varargin)

figure;
hold on
for i = 1:length(varargin)
    histogram(varargin{i}, min(cat(1,varargin{:})):0.005:max(cat(1,varargin{:})))
end
hold off

