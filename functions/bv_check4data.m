function [subjectdata, check, varargout] = bv_check4data(subjectFolderPath, varargin)

nArgs = length(varargin);

check = true;
if exist ([subjectFolderPath filesep 'Subject.mat'],'file')
    fprintf('\t loading Subject.mat ... ')
    load([subjectFolderPath filesep 'Subject.mat'])
    fprintf('done! \n')
else
    warning('No Subject.mat file found')
    check = false;
    varargout = [];
    return
end

[~, subjectName] = fileparts(subjectFolderPath);
if ~isempty(varargin)
    for i = 1:nArgs
        if isfield(subjectdata.PATHS, upper(varargin{i}))
            [~, filename, ext] = fileparts(subjectdata.PATHS.(upper(varargin{i})));
            if exist(subjectdata.PATHS.(upper(varargin{i})),'file')
                fprintf('\t loading %s%s ... ', filename, ext)
                output = load(subjectdata.PATHS.(upper(varargin{i})));
                fprintf('done! \n')
                fields = fieldnames(output);
                eval('varargout{i} = output.(fields{1});');
            else
                warning('%s: %s not found', subjectName, upper(varargin{i}))
                check = false;
                varargout{i} = [];
            end
        else
            warning('%s: %s is no field in subjectdata.PATHS', subjectName, upper(varargin{i}))
            check = false;
            varargout{i} = [];
        end
    end
end

