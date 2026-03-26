function [connectivityStates, subjConnStates, Qmax] = bv_detectConnectivityStates(As, randperms)

if ~iscell(As)
    error(["Input As is required to be a cell with length = nSubjects. ", ...
        "Each cell should contain the subject's As with dim: nchanxchanxntrls"])
end
if nargin < 2
    randperms = 100;
end

% setting up fixed variables
maxSzWs = 10;
nsubj = length(As);
nchans = size(As{1},1);

% pre-allocating variables
As_out = nan(nchans, nchans, maxSzWs, nsubj);
Ci = cell(1,nsubj);
Q_out = zeros(1,nsubj);

updateWaitbar = waitbarParfor(nsubj, 'calculating connectivity states ... ');  % waitbar for progress
parfor i = 1:nsubj
    Ws = As{i};
    rmindx = all(isnan(bv_multisquareform(Ws)),2);
    Ws(:,:,rmindx) = [];
    
    % Group adjacency matrices according to similarity by correlating
    % all matrices and finding communities in the resulting correlation
    % matrix (community_louvain)
    R = corr(bv_multisquareform(Ws)');
    R(R<0)=0;
    R(1:size(R,1)+1:end) = 0;
    
    Ci_tmp = zeros(size(Ws,3),randperms);
    Q = zeros(1,randperms);
    for t = 1:randperms
        [Ci_tmp(:,t), Q(t)] = community_louvain(R);
    end
    [~,imax] = max(Q);
    Q_out(i) = max(Q);
    Ci{i} = Ci_tmp(:,imax);    
    
    connStates = bv_multisquareform(splitapply(@nanmean, bv_multisquareform(Ws), Ci{i}), false);  % summarize over communities to get individual connectivity states
    
    % save individual connectivity states in output variable, add nan
    % matrices to make sure the 4-dimentional matrix can be indexed
    % correctly
    n = size(connStates,3);
    nanmat = nan(size(connStates,1), size(connStates,2), maxSzWs-n);
    connStates = cat(3, connStates, nanmat);
    try
        As_out(:,:,:,i) = connStates;
    catch
        updateWaitbar()
        error('%1.0f: %s', s, lasterr())
    end
    updateWaitbar()

end

% remove unnecessary nan matrices from As_out
selnans = squeeze(all(all(all(isnan(As_out),1),2),4));
As_out = As_out(:,:,~selnans,:);

% calculate connectivity states using all individual connectivity states in
% As_out
allWs = reshape(As_out, [nchans nchans size(As_out,3)*size(As_out,4)]);
sqWs = bv_multisquareform(allWs);
sqWs(all(isnan(sqWs),2),:)=[];

R = corr(sqWs');
R(R < 0) = 0;
Ci_pop = zeros(size(R, 1), randperms);
parfor i = 1:randperms
    [Ci_pop(:,i), Q_pop(i)] = community_louvain(R);
end

[Qmax, imax] = max(Q_pop);
Ci_pop2 = Ci_pop(:, imax);
connectivityStates = bv_multisquareform(splitapply(@nanmean, sqWs, Ci_pop2), false);

nConnStates = size(connectivityStates,3);
subjWs = zeros(nchans, nchans, nConnStates, nsubj);
cimax = cell(1, nsubj);
for i = 1:nsubj
    R = corr(bv_multisquareform(As{i})', bv_multisquareform(connectivityStates)');
    [~, cimax{i}] = max(R,[],2);
    subjWs(:,:,:,i) = bv_multisquareform(splitapply(@nanmean, bv_multisquareform(As{i}), cimax{i}), false);

    for j = 1:nConnStates
        subjConnStates{i,j} = As{i}(:,:,cimax{i}==j);
    end
end




