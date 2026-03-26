clear results ICCresults graph
str = 'pli5';

a = dir([str '_*.mat']);
resultStr = {a.name};



%     'wpli_debiased_delta.mat',...
%     'wpli_debiased_theta.mat',...
%     'wpli_debiased_alpha1.mat',...
%     'wpli_debiased_alpha2.mat',....
%     'wpli_debiased_beta.mat',...
%     'wpli_debiased_gamma.mat'};

% figureStr = {'conMatrices', ...
%     'R_corrCorrMatrix', ...
%     'scatterGrpAvg', ...
%     'plotGrpAvg', ...
%     'plotConnDist', ...
%     'plotUnitwiseDist'...
%     'degreeTopoplot'};

figureStr = {'barPlotGlobConn'};
figure;
hold on
for i = 1:length(resultStr)
    
    switch(figureStr{1})
        case {'conMatrices', ...
                'R_corrCorrMatrix', ...
                'scatterGrpAvg', ...
                'plotGrpAvg', ...
                'plotConnDist', ...
                'plotUnitwiseDist'...
                'degreeTopoplot',...
                'ccTopoplot'}
            %
            %             for iFig = 1:length(figureStr)
            %                 currFigStr = figureStr{iFig};
            %                 bv_plotResults(resultStr{i}, currFigStr, 0)
            %             end
            disp(resultStr{i})
            fprintf('\t loading ... ')
            load(resultStr{i})
            fprintf('done! \n')
            
            if strcmpi(figureStr,'conMatrices')
                conMatrices(:,i) = results.conMatrices;
            end
            
            
            
        case 'barPlotGlobConn'
            
            disp(resultStr{i})
            fprintf('\t loading ... ')
            load(resultStr{i})
            fprintf('done! \n')
            
            globConn(i) = results.r_scanwise;
            globConnCI(i,:) = results.globICC_CI;
            
            freqs{i} = freqband;
            
        case 'barUnitWiseConn'
            
            disp(resultStr{i})
            fprintf('\t loading ... ')
            load(resultStr{i})
            fprintf('done! \n')
            
            output = bv_summarizeResults('ns_wpli_debiased5_');
            
            unitWiseConn(i) = results.mr_unitwise;
            unitWiseConnSE(i) = 2*nanstd(results.r_unitwise) / sqrt(length(results.r_unitwise));
            unitWise75Conn(i) = results.mr_unitwise75;
            unitWise75ConnSE(i) = 2*nanstd(results.r_unitwise75) / sqrt(length(results.r_unitwise75));
            
    end
    
    
end

wellSorted = {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'};



% figure;
% boxplot(conMatrices)