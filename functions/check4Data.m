function [subjectdata, check, varargout] = check4Data(subjectFolderPath, varargin)
% Loads Subject.mat and optionally one or more data files for a subject.
%
% Args:
%     subjectFolderPath (str): Full path to the subject directory containing
%         ``Subject.mat``.
%     inputName (str, optional): One or more ``subjectdata.PATHS`` field
%         names to load. Each name is matched case-insensitively. Pass
%         multiple names as additional arguments.
%
% Returns:
%     subjectdata (struct): Subject metadata struct loaded from
%         ``Subject.mat``, or ``[]`` if ``Subject.mat`` was not found.
%     check (logical): ``true`` if ``Subject.mat`` was found and all
%         requested data files exist on disk; ``false`` otherwise.
%     data1, data2, ... (any, optional): Loaded data for each requested
%         ``inputName``, in the same order as the arguments. An entry is
%         ``[]`` if the corresponding file was not found (all entries are
%         ``[]`` if ``Subject.mat`` itself was not found).
%
% Example:
%     Load only the subject metadata:
%
%     ```matlab
%     subjectFolderPath = fullfile(PATHS.SUBJECTS, 'B12345_99m');
%     [subjectdata, check] = check4Data(subjectFolderPath);
%     ```
%
%     Load subject metadata and a preprocessed data file:
%
%     ```matlab
%     [subjectdata, check, data] = check4Data(subjectFolderPath, 'CLEANED');
%     ```

%% get options
nArgs = length(varargin);

%% load Subject.mat
check = true;
if exist ([subjectFolderPath filesep 'Subject.mat'],'file')
    fprintf('\t loading Subject.mat ... ')
    load([subjectFolderPath filesep 'Subject.mat']) %#ok<LOAD>
    fprintf('done! \n')
else
    warning('No Subject.mat file found in %s', subjectFolderPath)
    check = false;
    subjectdata = [];
    varargout = cell(1, nArgs);
    return
end

%% load data files
[~, subjectName] = fileparts(subjectFolderPath);
if ~isempty(varargin)
    for i = 1:nArgs
        if isfield(subjectdata.PATHS, upper(varargin{i})) %#ok<NODEF>
            [~, filename, ext] = fileparts(subjectdata.PATHS.(upper(varargin{i})));
            if exist(subjectdata.PATHS.(upper(varargin{i})),'file')
                fprintf('\t loading %s%s ... ', filename, ext)
                output = load(subjectdata.PATHS.(upper(varargin{i})));
                fprintf('done! \n')
                fields = fieldnames(output);
                varargout{i} = output.(fields{1}); %#ok<AGROW>
            else
                warning('⚠ %s: %s not found', subjectName, upper(varargin{i}))
                check = false;
                varargout{i} = []; %#ok<AGROW>
            end
        else
            warning('⚠ %s: %s is no field in subjectdata.PATHS', subjectName, upper(varargin{i}))
            check = false;
            varargout{i} = []; %#ok<AGROW>
        end
    end
end