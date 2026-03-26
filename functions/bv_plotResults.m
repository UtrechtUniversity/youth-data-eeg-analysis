function varargout = bv_plotResults(resultsName, vars, saveflag)

if ~iscell(vars)
    vars = {vars};
end

disp(resultsName)
try
    fprintf('\t loading ... ')
    load(resultsName)
    fprintf('done! \n')
catch
    error('%s not found', resultsName)
end

if saveflag
    figureDir = [pwd filesep 'figures' filesep resultsName];
    if ~exist(figureDir, 'dir')
        mkdir(figureDir)
    end
end

freqband = strsplit(resultsName, '_');
freqband = freqband{end};

for iVar = 1:length(vars)
    currVar = vars{iVar};

    switch currVar
        case 'conMatrices'
            
            if ~isfield(results, 'conMatrices')
                error('%s not found in %s', currVar, resultsName)
            end
            
            fprintf('\t creating R_conMatrices figure ... ')
            varargout{iVar} = figure; 
            bar(results.conMatrices)
            title([freqband ' individual correlation coefficient between sessions'], 'FontSize', 20)
            ylabel('Correlation coefficient (in r)', 'FontSize', 14)
            xlabel('Subjects', 'FontSize', 14)

            set(gca, 'YLim', [(min(results.conMatrices) - 0.05) 1])
            set(gca, 'XLim', [0 length(results.conMatrices)+1])
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename = [freqband '_bar_corrConMatrices'];
                export_fig(varargout{iVar}, [figureDir filesep filename], '-dpng', '-transparent', '-r300')
                fprintf('done! \n')
                close all
            end
                
            
        case 'corrCorrMatrix'
            
            if ~isfield(results, 'corrCorrMatrix')
                error('%s not found in %s', currVar, resultsName)
            end
            
            fprintf('\t creating R_conMatrices figure ... ')
            varargout{iVar} = figure;
            imagesc(results.corrCorrMatrix)
            colorbar;
            axis('square')
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename = 'imR_corrCorrMatrix.png';
                export_fig(varargout{iVar}, [figureDir filesep filename], '-dpng', '-r300')
                fprintf('done! \n')
                close all
            end
            
        case 'scatterGrpAvg'
            fprintf('\t creating scatter group averages ... ')
            varargout{iVar} = figure;
            W1 = squeeze(nanmean(Ws(:,:,:,1),3));
            W2 = squeeze(nanmean(Ws(:,:,:,2),3));
            00
            scatter(squareform(W1), squareform(W2), 20, [0.5 0.5 0.5], 'filled')
            title([freqband ' group averaged scatterplot'], 'FontSize', 20)
            axis('square')
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename = [freqband '_scatterGrAvg'];
                export_fig(varargout{iVar}, [figureDir filesep filename], '-dpng', '-transparent', '-r300')
                fprintf('done! \n')
                close all
            end
            
        case 'plotGrpAvg'
            fprintf('\t plot group-averaged matrices... ')
%             varargout{iVar} = figure;
            W1 = squeeze(nanmean(Ws(:,:,:,1),3));
            W2 = squeeze(nanmean(Ws(:,:,:,2),3));
            
            fig1 = figure('units','normalized', 'Position', [0 0 0.5 1]);
            imagesc(W1)
            axis('square')
            set(gca, 'CLim', [min([min(nansquareform(W1)) min(nansquareform(W2))]) ...
                max([max(nansquareform(W1)) max(nansquareform(W2))])])
            colorbar
            set(gca, 'XTick', [], 'YTick', [])
            
            fig2 = figure('units','normalized', 'Position', [0 0 0.5 1]);
            imagesc(W2)
            axis('square')
            colorbar
%             set(gcf, 'units', 'normalized', 'Position', [0 0 1 1])
            set(gca, 'CLim', [min([min(nansquareform(W1)) min(nansquareform(W2))]) ...
                max([max(nansquareform(W1)) max(nansquareform(W2))])])
            set(gca, 'XTick', [], 'YTick', [])
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename1 = 'groupAvgMat1';
                filename2 = 'groupAvgMat2';

                export_fig(fig1, [figureDir filesep filename1], '-dpng', '-transparent', '-r300')
                export_fig(fig2, [figureDir filesep filename2], '-dpng', '-transparent', '-r300')
                fprintf('done! \n')
                close all
            end
        case 'plotConnDist'
%             rng(12857)
            subjNr = 1:4; %randsample(1:size(Ws,3),4);
            fprintf(['\t plot connectivity distribution for subjects: ' repmat('%1.0f, ', 1, 4)], subjNr)

            fig_cDist = bv_plotConnDistr(Ws, subjNr);
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename = 'connetivityDistribution.png';
%                 set(fig_cDist, 'units', 'Normalized', 'Position', [0 0 1 1])
                
                export_fig(fig_cDist, [figureDir filesep filename], '-dpng', '-transparent', '-r300')
                fprintf('done! \n')
                close all
            end
            
        case 'plotUnitwiseDist'
            fprintf('\t plot unitwise distribution...' )

            bv_plotUnitDist(results.r_unitwise);
            fprintf('done! \n')
            
            if saveflag
                fprintf('\t saving figure ... ')
                filename = 'unitwiseDist.png';
                set(fig_uDist, 'units', 'Normalized', 'Position', [0 0 1 1])
                export_fig(fig_uDist, [figureDir filesep filename], '-dpng', '-transparent', '-r300')
                fprintf('done! \n')
                close all
            end
            
        case 'degreeTopoplot'
            fprintf('\t topoplot degree ...' )
            
            xmax = max([sum(results.avgW1), sum(results.avgW2)]);
            xmin = min([sum(results.avgW1), sum(results.avgW2)]);
            
            evalc('degtop1 = topoplotWrapper(sum(results.avgW1), chans);');
            evalc('degtop2 = topoplotWrapper(sum(results.avgW2), chans);');
            
            fprintf('done! \n')
            if saveflag
                fprintf('\t saving figure ... ')
                filename1 = 'degreesTopo1.png';
                filename2 = 'degreesTopo2.png';
%                 set(degtop1, 'units', 'Normalized', 'Position', [0 0 0.5 1])
%                 set(degtop2, 'units', 'Normalized', 'Position', [0 0 0.5 1])
                
                export_fig(degtop1, [figureDir filesep filename1], '-dpng', '-transparent', '-r300')
                export_fig(degtop2, [figureDir filesep filename2], '-dpng', '-transparent', '-r300')
                
                fprintf('done! \n')
                close all
            end
            
        case 'ccTopoplot'
            W1nrm = weight_conversion(results.avgW1, 'normalize');
            W2nrm = weight_conversion(results.avgW2, 'normalize');
            
            C1 = clustering_coef_wu(W1nrm);
            C2 = clustering_coef_wu(W2nrm);
                 
            evalc('ctop1 = topoplotWrapper(C1, chans);');
            evalc('ctop2 = topoplotWrapper(C2, chans);');
            
            
    end
end

