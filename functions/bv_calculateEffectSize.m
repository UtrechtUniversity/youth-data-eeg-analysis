function d = bv_calculateEffectSize(y)

m = nanmean(y);
sd = nanstd(y);

sd_pooled = sqrt((sd(1).^2 + sd(2).^2) ./ 2);

d = abs((m(1) - m(2)) / sd_pooled);