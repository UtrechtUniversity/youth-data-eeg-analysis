function bv_graphAnalysis(cfg, resultsfile)

threshtype  = ft_getopt(cfg, 'threshtype');
threshval   = ft_getopt(cfg, 'threshval');
analyses    = ft_getopt(cfg, 'analyses', 'sessionSummary');
saveFigures = ft_getopt(cfg, 'saveFigures', 'yes');

if nargin < 2
    error('Please input (path to) resultsfile')
end
if nargin < 1
    error('Please input config file')
end

try
    [PATHS.RESULTS, filename, ~] = fileparts(resultsfile);
    fprintf('loading %s ... ', filename)
    load(resultsfile)
    fprintf('done! \n')
catch
    error('%s not found', resultsfile)
end

if isempty(PATHS.RESULTS)
    PATHS.RESULTS = pwd;
end

PATHS.GRAPHRESULTS = [PATHS.RESULTS filesep 'graph'];
if ~exist(PATHS.GRAPHRESULTS, 'dir')
    mkdir(PATHS.GRAPHRESULTS)
end

PATHS.SUMMARY = [PATHS.GRAPHRESULTS filesep 'summary'];
if ~exist(PATHS.SUMMARY, 'dir')
    mkdir(PATHS.SUMMARY)
end

cDims = strsplit(dims, '-');
sessionDim = find(not(cellfun(@isempty, strfind(cDims, 'session'))));
subjectDim = find(not(cellfun(@isempty, strfind(cDims, 'subj'))));

nSubj = size(Ws, subjectDim);
nSes = size(Ws, sessionDim);

if exist('findCoords', 'file')
    [xScreenLength, yScreenLength] = findCoords;
else
    xScreenLength = 1;
    yScreenLength = 1;
end

switch analyses
    case 'sessionSummary'

        fprintf('SESSION SUMMARY \n')
        fprintf('\t creating figures ... ')
        A = squeeze(nanmean(Ws,subjectDim));
        
        A_sq = zeros(length(squareform(A(:,:,1))), nSes);
        mPlot = figure;
        for iSes = 1:nSes
            A_sq(:,iSes) = squareform(A(:,:,iSes));
            
            subplot(1,2,iSes)
            imagesc(A(:,:,iSes))
            axis square
            
        end
        set(gcf, 'units', 'normalized', 'Position', [0 0 xScreenLength yScreenLength])
        
        r = corr(A_sq, 'rows', 'pairwise');
        sPlot = figure;
        plot(A_sq(:,1),A_sq(:,2) , '.', 'MarkerSize', 15);
        title(['Scatter plot averaged connectivity matrix: ' freqband  ' frequency. '...
            'R^2 = ' num2str(r(2).^2)], 'FontSize', 14)
        xlabel('Session 1', 'FontSize', 14)
        ylabel('Session 2', 'FontSize', 14)
        lims = [min(min(A_sq)) - mean(std(A_sq)) max(max(A_sq)) + mean(std(A_sq))];
        set(gca, 'XLim', lims, 'YLim', lims, 'FontSize', 14)
        axis('square')
        
        set(gcf, 'units', 'normalized', 'Position', [0 0 xScreenLength/2 yScreenLength])
        fprintf('done! \n')
        
        if strcmpi(saveFigures, 'yes')
            fprintf('\t saving figures ... ')
            
            PATHS.SUMMARYFIGURES = [PATHS.SUMMARY filesep 'figures'];
            if ~exist(PATHS.SUMMARYFIGURES, 'dir')
                mkdir(PATHS.SUMMARYFIGURES)
            end
            
            add = strsplit(resultsfile, '_');
            add = strsplit(add{end}, '.');
            
            sfigname = [add{1} '_mScatter'];
            mfigname = [add{1} '_mConn'];

            print(sPlot, [PATHS.SUMMARYFIGURES filesep sfigname], '-dpng', '-r300')
            print(mPlot, [PATHS.SUMMARYFIGURES filesep mfigname], '-dpng', '-r300')
            fprintf('done! \n')
            close all
        end
  
end





