function bv_updateSubjectSummary(path2subjectsummary, subjectdata)

load(path2subjectsummary, 'subjectdatasummary')
subjectdatafields = fields(subjectdata);
subjectdatasummaryfields = fields(subjectdatasummary);
missingFieldsSummary = subjectdatafields(find(not(ismember(subjectdatafields, ...
    subjectdatasummaryfields))));

if ~isempty(missingFieldsSummary)
    for i = missingFieldsSummary'
        switch class(subjectdata.(i{:}))
            case 'struct'
                [subjectdatasummary(1:end).(i{:})] = deal(struct);
            case 'double'
                [subjectdatasummary(1:end).(i{:})] = deal(NaN);
            case 'char'
                [subjectdatasummary(1:end).(i{:})] = deal('');
            case 'cell'
                [subjectdatasummary(1:end).(i{:})] = deal(cell(0));
        end
    end
end

missingFieldsSubjectdata = subjectdatasummaryfields(find(not(ismember(subjectdatasummaryfields, ...
    subjectdatafields))));

if ~isempty(missingFieldsSubjectdata)
    for i = missingFieldsSubjectdata'
        switch class(subjectdatasummary(1).(i{:}))
            case 'struct'
                subjectdata.(i{:}) = struct;
            case 'double'
                subjectdata.(i{:}) = NaN;
            case 'char'
                subjectdata.(i{:}) = '';
            case 'cell'
                subjectdata.(i{:}) = cell(0);
        end
    end
end

subjectIndx = find(ismember({subjectdatasummary.subjectName}, ...
    subjectdata.subjectName));

subjectdatasummary(subjectIndx) = subjectdata;

fprintf('\t saving SubjectSummary.mat...')
save(path2subjectsummary, 'subjectdatasummary')
fprintf('done \n')
