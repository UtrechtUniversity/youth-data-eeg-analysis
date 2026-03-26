function [subjectresults] = bv_cleanSubjectResults(subjectresults);

uniquePseudos = unique({subjectresults.pseudocode});
uniqueAgegroups = unique({subjectresults.agegroup});

for i = 1:length(uniquePseudos)
    

