function bv_write2JASP(T, filename, depVar, fixedVar)

if ~iscell(depVar)
    depVar = {depVar};
end
if ~iscell(fixedVar);
    fixedVar = {fixedVar};
end
vars = cat(2, depVar, fixedVar);

T_out = T(:, ismember(T.Properties.VariableNames, vars));

writetable(T_out, filename)