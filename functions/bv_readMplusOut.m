function fitout = bv_readMplusOut(filename)

fitout.filename = filename;
fid = fopen(fitout.filename, 'r');
counter = 0;
while 1
    counter = counter + 1;
    line = fgetl(fid);

    if line==-1
        fclose all;
        break
    end

    dat{counter} = line;
end
a = cellfun(@strsplit, dat(find(contains(dat, ...
    '           ESTIMATED CORRELATION MATRIX FOR THE LATENT VARIABLES'))+1), 'Un',0);
labels = unique(cat(2,a{:}), 'stable');
labels(1) = [];
fitout.varlabels = labels;

a = regexp(dat,'\d.*','Match');
c = cellfun(@(x) strsplit(x{:},' '), a,'un',0);
d = cellfun(@(x) sscanf(sprintf('%s',x{2:end}), '%f'),c,'un',0);

noVarsWidth = max(cellfun(@length,d));
noVarLabels = length(labels);
remainder = rem(noVarLabels,noVarsWidth);
counts = floor(noVarLabels/noVarsWidth);
upcount = ceil(noVarLabels/noVarsWidth);
trailsize = 2;
headersize = 3;

lengthMatrix = noVarLabels*counts+remainder - noVarsWidth + ...
    (trailsize+headersize)*upcount - 1;

%% Read Input Instructions
startInd = find(contains(dat, 'INPUT INSTRUCTIONS'));
startInd = startInd(1);
endInd = find(contains(dat, 'OUTPUT'));
endInd = endInd(1);

fitout.input = dat(startInd:endInd)';

%% Find and label seperate models
indx = contains(dat, 'ESTIMATED SAMPLE STATISTICS FOR');
fitout.group = cellfun(@(x) x{end}, cellfun(@strsplit, dat(indx),'un',0), 'un',0);

%% Read Model Fit Information
startInd = find(contains(dat, 'MODEL FIT INFORMATION'));
endInd = find(contains(dat, 'MODEL RESULTS'));
endInd = endInd(1);
fitInfo = dat(startInd:endInd-1)';

fitout.fitinfo.freeparams = bv_getNumbers(fitInfo{contains(fitInfo, 'Number of Free Parameters')});

% Loglikelihood
H0Val = bv_getNumbers(fitInfo{contains(fitInfo, 'H0 Value')});
H0Scaling = bv_getNumbers(fitInfo{contains(fitInfo, 'H0 Scaling')});
H1Val = bv_getNumbers(fitInfo{contains(fitInfo, 'H1 Value')});
H1Scaling = bv_getNumbers(fitInfo{contains(fitInfo, 'H1 Scaling')});
fitout.fitinfo.loglikelihood.h0.val = H0Val;
fitout.fitinfo.loglikelihood.h0.scaling = H0Scaling;
fitout.fitinfo.loglikelihood.h1.val = H1Val;
fitout.fitinfo.loglikelihood.h1.scaling = H1Scaling;

% Information Criteria
fitout.fitinfo.IC.AIC = bv_getNumbers(fitInfo{contains(fitInfo, 'Akaike (AIC)')});
fitout.fitinfo.IC.BIC = bv_getNumbers(fitInfo{contains(fitInfo, 'Bayesian (BIC)')});
fitout.fitinfo.IC.BICAdjusted = bv_getNumbers(fitInfo{contains(fitInfo, 'Adjusted BIC')});

% Chi-square test of model fit
startInd = find(ismember(dat, 'Chi-Square Test of Model Fit'));
endInd = find(ismember(dat, 'Chi-Square Contribution From Each Group'));
if isempty(endInd)
    endInd = find(ismember(dat, 'RMSEA (Root Mean Square Error Of Approximation)'));
end
chiSquareInfo = dat(startInd:endInd-1)';
fitout.fitinfo.chi2.val = bv_getNumbers(chiSquareInfo{contains(chiSquareInfo, ' Value')});
fitout.fitinfo.chi2.dof = bv_getNumbers(chiSquareInfo{contains(chiSquareInfo, ' Degrees of Freedom')});
fitout.fitinfo.chi2.p = bv_getNumbers(chiSquareInfo{contains(chiSquareInfo, ' P-Value')});
fitout.fitinfo.chi2.scaling = bv_getNumbers(chiSquareInfo{contains(chiSquareInfo, ' Scaling')});

% If doing groups -> Chi-square contribution
if length(fitout.group) > 1
    for i = 1:length(fitout.group)
        fitout.fitinfo.chi2contribution.(fitout.group{i}) = bv_getNumbers(fitInfo{contains(fitInfo, [' ' fitout.group{i}])});
    end
end

% Root Mean Square Error of Approximation
fitout.fitinfo.RMSEA.est = bv_getNumbers(fitInfo{contains(fitInfo, ' Estimate')});
ci = bv_getNumbers(fitInfo{contains(fitInfo, ' 90 Percent C.I.')});
fitout.fitinfo.RMSEA.ci90 = ci([3 4])';
fitout.fitinfo.RMSEA.est = bv_getNumbers(fitInfo{contains(fitInfo, ' Estimate')});

% CFI/TLI
fitout.fitinfo.CFI = bv_getNumbers(fitInfo{contains(fitInfo, ' CFI')});
fitout.fitinfo.TLI = bv_getNumbers(fitInfo{contains(fitInfo, ' TLI')});

startInd = find(ismember(dat, 'STANDARDIZED MODEL RESULTS'));
endInd = find(ismember(dat, 'QUALITY OF NUMERICAL RESULTS'))-1;

dat2use = dat(startInd:endInd);
counter = 0;
est = zeros(length(fitout.varlabels), length(fitout.varlabels), length(fitout.group));
se = zeros(length(fitout.varlabels), length(fitout.varlabels), length(fitout.group));
p = zeros(length(fitout.varlabels), length(fitout.varlabels), length(fitout.group));
while counter < length(dat2use)
    counter = counter + 1;
    line = dat2use{counter};

    if isempty(line)
        continue
    end

    linesplit = strsplit(line);
    linesplit(cellfun(@isempty, linesplit)) =[];
    if contains(line, fitout.group)
        groupIndx = find(contains(fitout.group, linesplit));
        continue

    elseif contains(line, {'ON', 'WITH'})
        tovar = find(contains(fitout.varlabels, linesplit));

        while 1
            counter = counter + 1;
            line = dat2use{counter};

            if isempty(line)
                break
            end

            linesplit = strsplit(line);
            linesplit(cellfun(@isempty, linesplit)) =[];
            fromvar = find(contains(fitout.varlabels, linesplit));
            a = cellfun(@(x) ismember(1,regexp(x, '^-?\d.*')), linesplit, 'Un',0);
            b = linesplit([a{:}]);
            c = regexp(b, '^-?\d.*', 'Match');
            c = [c{:}];
            d = sscanf(sprintf('%s', [c{:}]), '%f');

            fitout.params.est(fromvar,tovar,groupIndx) = d(1);
            fitout.params.se(fromvar,tovar,groupIndx) = d(2);
            fitout.params.p(fromvar,tovar,groupIndx) = d(4);
        end

    elseif contains(line, {'Means', 'Intercepts'})
        while 1
            counter = counter + 1;
            line = dat2use{counter};

            if isempty(line)
                break
            end

            linesplit = strsplit(line);
            linesplit(cellfun(@isempty, linesplit)) =[];
            fromvar = find(contains(fitout.varlabels, linesplit));
            a = cellfun(@(x) ismember(1,regexp(x, '^-?\d.*')), linesplit, 'Un',0);
            b = linesplit([a{:}]);
            c = regexp(b, '^-?\d.*', 'Match');
            c = [c{:}];
            d = sscanf(sprintf('%s', [c{:}]), '%f');

            fitout.means.est(fromvar,groupIndx) = d(1);
            fitout.means.se(fromvar,groupIndx) = d(2);
            fitout.means.p(fromvar,groupIndx) = d(4);
        end

    elseif contains(line, {'Variances'})
        while 1
            counter = counter + 1;
            line = dat2use{counter};

            if isempty(line)
                break
            end

            linesplit = strsplit(line);
            linesplit(cellfun(@isempty, linesplit)) =[];
            fromvar = find(contains(fitout.varlabels, linesplit));
            a = cellfun(@(x) ismember(1,regexp(x, '^-?\d.*')), linesplit, 'Un',0);
            b = linesplit([a{:}]);
            c = regexp(b, '^-?\d.*', 'Match');
            c = [c{:}];
            d = sscanf(sprintf('%s', [c{:}]), '%f');

            fitout.var.est(fromvar,groupIndx) = d(1);
            fitout.var.se(fromvar,groupIndx) = d(2);
            fitout.var.p(fromvar,groupIndx) = d(4);
        end
    end
end

for i = 1:groupIndx
    fitout.params.est(:,:,i) = rot90(flipud(triu(fitout.params.est(:,:,i))),-1) + tril(fitout.params.est(:,:,i));
    fitout.params.se(:,:,i) = rot90(flipud(triu(fitout.params.se(:,:,i))),-1) + tril(fitout.params.se(:,:,i));
    fitout.params.p(:,:,i) = rot90(flipud(triu(fitout.params.p(:,:,i))),-1) + tril(fitout.params.p(:,:,i));
end


%% Read Correlation Matrices
fitout.corr.vals = addMatrices(dat, ...
    '           ESTIMATED CORRELATION MATRIX FOR THE LATENT VARIABLES', ...
    lengthMatrix, noVarsWidth, labels);


%% Read Correlation P-Matrices
fitout.corr.P = addMatrices(dat, ...
    '           TWO-TAILED P-VALUE FOR ESTIMATED CORRELATION MATRIX FOR THE LATENT VARIABLES', ...
    lengthMatrix, noVarsWidth, labels);

%% Read Covariance Matrices
fitout.cov.vals = addMatrices(dat, ...
    '           ESTIMATED COVARIANCE MATRIX FOR THE LATENT VARIABLES', ...
    lengthMatrix, noVarsWidth, labels);

%% Read Covariance P-Matrices
fitout.cov.P = addMatrices(dat, ...
    '           TWO-TAILED P-VALUE FOR ESTIMATED COVARIANCE MATRIX FOR THE LATENT VARIABLES', ...
    lengthMatrix, noVarsWidth, labels);



function matOut = addMatrices(dat, str, lengthMatrix, noVarsWidth, labels)

mat = nan(length(labels));
mat = triu(mat);
mat(1:size(mat,2)+1:end) = 0;
startInd = find(ismember(dat, str));
startInd = startInd(1:3:end);
endInd = startInd + lengthMatrix;

for i = 1:length(startInd)
    b = dat(startInd(i):endInd(i))';
    b(not(cellfun(@isempty, regexp(b, '^  ')))) = [];
    b(cellfun(@isempty, b)) = [];

    a = regexp(b,'\d.*','Match');
    c = cellfun(@(x) strsplit(x{:},' '), a,'un',0);
    d = cellfun(@(x) sscanf(sprintf('%s',x{2:end}), '%f'),c,'un',0);

    ind = find(cellfun(@length, d)==1);
    mat1 = d(ind(1):ind(2)-1);
    mat2 = d(ind(2):ind(3)-1);
    mat3 = d(ind(3):end);

    for j = 1:length(mat1)
        mat(j,1:length(mat1{j})) = mat1{j};
    end
    for j = 1:length(mat2)
        mat(j+noVarsWidth,(1+noVarsWidth):(noVarsWidth+length(mat1{j}))) = mat1{j};
    end
    for j = 1:length(mat3)
        mat(j+noVarsWidth*2,(1+noVarsWidth*2):(noVarsWidth*2+length(mat1{j}))) = mat1{j};
    end
    matOut(:,:,i) = mat;
end
bv_setDiag(matOut, 1);


