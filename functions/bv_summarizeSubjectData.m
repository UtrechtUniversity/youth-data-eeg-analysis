function summarizedSubjectdata = bv_summarizeSubjectData

eval('setPaths')
eval('setOptions')

subjectFolders = dir([PATHS.SUBJECTS filesep '**' filesep OPTIONS.sDirString '*']);
subjectFolders = subjectFolders([subjectFolders.isdir])
subjectFoldernames = {subjectFolders.name};
subjectPaths = {subjectFolders.folder};
[subjectFoldernames,sortIndx] = sort(subjectFoldernames);
subjectPaths = subjectPaths(sortIndx);

counter = 0;
for i = 1:length(subjectFoldernames)
    counter = counter + 1;
    disp(subjectFoldernames{i})
    subjectdata = bv_check4data([subjectPaths{i} filesep subjectFoldernames{i}]);
    
    if counter == 1
        summarizedSubjectdata = subjectdata;
    else
        subjectdatafields = fields(subjectdata);
        subjectdatasummaryfields = fields(summarizedSubjectdata);
        missingFieldsSummary = subjectdatafields(find(not(ismember(subjectdatafields, ...
            subjectdatasummaryfields))));
        
        if ~isempty(missingFieldsSummary)
            for j = missingFieldsSummary'
                switch class(subjectdata.(j{:}))
                    case 'struct'
                        [summarizedSubjectdata(1:end).(j{:})] = deal(struct);
                    case 'double'
                        [summarizedSubjectdata(1:end).(j{:})] = deal(NaN);
                    case 'char'
                        [summarizedSubjectdata(1:end).(j{:})] = deal('');
                    case 'cell'
                        [summarizedSubjectdata(1:end).(j{:})] = deal(cell(0));
                end
            end
        end
        
        missingFieldsSubjectdata = subjectdatasummaryfields(find(not(ismember(subjectdatasummaryfields, ...
            subjectdatafields))));
        
        if ~isempty(missingFieldsSubjectdata)
            for j = missingFieldsSubjectdata'
                switch class(summarizedSubjectdata(1).(j{:}))
                    case 'struct'
                        subjectdata.(j{:}) = struct;
                    case 'double'
                        subjectdata.(j{:}) = NaN;
                    case 'char'
                        subjectdata.(j{:}) = '';
                    case 'cell'
                        subjectdata.(j{:}) = cell(0);
                end
            end
        end
        
        summarizedSubjectdata(i) = subjectdata;
    end
end

