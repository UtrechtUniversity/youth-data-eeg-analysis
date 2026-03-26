function cov = calculateCoV(Y)

for i = 1:size(Y, 2)
    cov(i) = nanstd(Y(:,i))/nanmean(Y(:,i));
end