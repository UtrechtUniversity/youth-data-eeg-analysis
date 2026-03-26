function out = bv_collateResults(inputStr, varname)

if nargin < 1
    error('No inputStr given')
end
if nargin < 2
    varname = '';
end

eval('setPaths')
eval('setOptions')

subjectdirflags = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);

for i = 1:length(subjectdirflags)
    lng = printPercDone(length(subjectdirflags), i);
    evalc('[subjectdata, data] = bv_check4data([subjectdirflags(i).folder filesep subjectdirflags(i).name], inputStr);');
    if ~isempty(varname)
        out{i} = data.(varname);
    else
        out(i) = data;
    end
    fprintf(repmat('\b', 1, lng))
end
    
