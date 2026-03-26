function varOut = bv_splitVarMonthly(varIn, ageInDays)

if not(numel(varIn)==numel(ageInDays))
    error('different size input variables')
end

ageInMonths = floor(ageInDays ./ 365 * 12);
ageInMonths(ageInMonths(:,1)>6,1) = 6;
ageInMonths(ageInMonths(:,1)<4,1) = 4;
ageInMonths(ageInMonths(:,2)>11,2) = 11;
ageInMonths(ageInMonths(:,2)<9,2) = 9;

varOut = NaN(length(ageInMonths),6);
for i = 1:length(ageInMonths)
    if not(isnan(ageInMonths(i,1)) || isnan(varIn(i,1)))
        varOut(i,ageInMonths(i,1)-3) = varIn(i,1);
    end
    
    if not(isnan(ageInMonths(i,2)) || isnan(varIn(i,2)))
        varOut(i,ageInMonths(i,2)-5) = varIn(i,2);
    end
end