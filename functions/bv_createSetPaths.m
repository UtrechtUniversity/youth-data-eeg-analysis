function filecreated = bv_createSetPaths(path2root, path2home)

fid = fopen([path2root filesep 'setPaths.m'], 'w');

fprintf(fid, '%% set all the paths necessary for analysis. Change according to your own \n%% needs. Save this file to your PATHS.ROOT folder so it can always be found \n%% by matlab during analysis\n');
fprintf(fid, '\n%% Paths to already existing folders\n');
fprintf(fid, 'PATHS.ROOT = ''%s''; %% analyses folder (subject & figure folders will be created here) \n', path2root);
fprintf(fid, 'PATHS.HOME = ''%s''; %% path to home folder (where you can find RAWS and PRPEROC usually)\n', path2home);
fprintf(fid, 'PATHS.RAWS = ''%s''; %% path to the directory of raw EEG files \n', [path2home filesep 'RAW']);
fprintf(fid, '\n %% Paths to folders to be created\n');
path2subjects = [path2root filesep 'Subjects'];
fprintf(fid, 'PATHS.SUBJECTS = ''%s''; %% path to subject directory\n', [path2subjects]);
fprintf(fid, 'PATHS.REMOVED = ''%s''; %% path to removed subjects directory\n', [path2subjects filesep 'removed']);
fprintf(fid, 'PATHS.CONFIG = ''%s''; %% path to config directory\n', [path2root filesep 'config']);
fprintf(fid, 'PATHS.SUMMARY = ''%s''; %% path to summary directory\n', [path2root filesep 'summary']);
fprintf(fid, 'PATHS.PIPELINE = ''%s''; %% path to pipeline functions\n', [path2home filesep 'functions' filesep]);
fprintf(fid, 'PATHS.FTPATH = ''''; %% path to FieldTrip directory\n');

fprintf(fid,'\n%% create, if necessary the folders \nif ~exist(PATHS.SUBJECTS, ''dir'')\n\tmkdir(PATHS.SUBJECTS)\nend\n');
fprintf(fid,'if ~exist(PATHS.REMOVED, ''dir'')\n\tmkdir(PATHS.REMOVED)\nend\n');
fprintf(fid,'if ~exist(PATHS.CONFIG, ''dir'')\n\tmkdir(PATHS.CONFIG)\nend\n');
fprintf(fid,'if ~exist(PATHS.SUMMARY, ''dir'')\n\tmkdir(PATHS.SUMMARY)\nend\n');

fprintf(fid, '\n%% add fieldtrip and its subfunctions path\n');
fprintf(fid, 'addpath(PATHS.FTPATH);\n');
fprintf(fid, 'ft_defaults;\n');
fprintf(fid, 'addpath(PATHS.PIPELINE);\n');

if exist([path2root filesep 'setPaths.m'], 'file') == 2
    filecreated = true(1);
else
    filecreated = false(1);
    warning('No setOptions.m file created at given location')
end

fclose(fid);

