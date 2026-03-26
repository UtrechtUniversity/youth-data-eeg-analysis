function bv_saveFigures(cfg)

fighandle   = ft_getopt(cfg, 'fighandle', gcf);
outputStr   = ft_getopt(cfg, 'outputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
filename    = ft_getopt(cfg, 'filename');
figtitle    = ft_getopt(cfg, 'figtitle');

if isempty(filename)
    error('no filename given')
end

eval(optionsFcn)
eval(pathsFcn)

% xScreenLength = 1;
% yScreenLength = 1;
% 
% if exist('WindowSize', 'file')
%     [xScreenSize, yScreenSize] = WindowSize(0);
%     set(0, 'units', 'pixels')
%     realScreenSize = get(0, 'ScreenSize');
%     xDiff = xScreenSize / realScreenSize(3);
%     xScreenLength = xScreenLength * xDiff;
%     yDiff = yScreenSize / realScreenSize(4);
%     yScreenLength = yScreenLength * yDiff;
%     
%     set(fighandle, 'units', 'normalized', 'Position', [0 0 xScreenLength yScreenLength])
% end

figureDir = [PATHS.FIGURES filesep outputStr];

if ~exist(figureDir, 'dir')
    mkdir(figureDir)
end

if ~isempty(figtitle)
    title(figtitle, 'FontSize', 14)
end

print(fighandle, [figureDir filesep filename], '-dpng')

close(fighandle)