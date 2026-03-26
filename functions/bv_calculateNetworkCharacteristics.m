function T = bv_calculateNetworkCharacteristics(T, spctrmvar, chars, prop_threshold)

if nargin < 4
    threshold = 1;
else
    threshold = prop_threshold;
end

if strcmpi(chars, 'all')
    chars = {'SWP', 'SW', 'strength'};
end

if range(cellfun(@(x) size(x,1), T.(spctrmvar))) ~=0 || ...
        range(cellfun(@(x) size(x,2), T.(spctrmvar))) ~=0
    error('Subjects do not have the same number of channels in their connectivity matrix')
end

strengthfield = [spctrmvar '_strength'];
swpfield = [spctrmvar '_SWP'];
swfield = [spctrmvar '_SW'];
cfield = [spctrmvar '_C'];
lfield = [spctrmvar '_L'];
qfield = [spctrmvar '_Q'];
lnrmfield = [spctrmvar '_Lnrm'];

spctrm = T.(spctrmvar);
kepttrials = true;
freqs = T.freq{1};
nfreqs = size(spctrm{1},4);
if kepttrials
    updateWaitbar = waitbarParfor(length(spctrm)*length(chars), "Calculate characteristics...");
    strength = zeros(length(spctrm), nfreqs);
    SWP = zeros(length(spctrm), nfreqs);
    C = SWP;
    L = SWP;
    parfor i = 1:length(spctrm)
        if isempty(spctrm{i})
            continue
        end
        thresh_spctrm = bv_thresholdMultipleWs(spctrm{i}, threshold)

        if ismember('strength', chars)
            if nfreqs == 1
                strength(i,:) = nanmedian(nanmean(bv_multisquareform(thresh_spctrm)));
            else
                strength(i,:) = nanmedian(nanmean(bv_multisquareform(thresh_spctrm),1),3);
            end
            updateWaitbar()
        end
        if ismember('SWP', chars)
            SWP(i,:) = nanmean(gr_calculateSmallworldPropensityWs(thresh_spctrm));
            updateWaitbar()
        end
        if ismember('Lnrm', chars)
            lambdas(i,:) = nanmean(gr_calculateNormalizedPathLength(thresh_spctrm, 'weighted'));
            updateWaitbar()
        end
        if ismember('modularity', chars)
            [~, Qout] = gr_calculateQModularity(thresh_spctrm, 'weighted');
            Q(i,:) = nanmean(Qout);
            updateWaitbar()
        end
        % if ismember('SW', chars)
        %     sz = size(spctrm{i});
        %     SWs = zeros(length(thresholds), length(freqs));
        %     for j = 1:length(thresholds)
        %         SWs(j,:) = ...
        %             nanmedian(reshape(gr_calculateSmallWorldnessHumphries(...
        %             reshape(spctrm{i}, [sz(1) sz(2) prod(sz(3:end))]), thresholds(j)), sz(3:4)));
        %     end
        %     SW(i,:,:) = SWs;
        %     updateWaitbar()
        % 
        % end
        if ismember('C', chars)
            C(i,:) = nanmedian(gr_calculateClusteringWs(thresh_spctrm, 'weighted'));
            updateWaitbar()
        end
        if ismember('L', chars)
            L(i,:) = nanmedian(gr_calculatePathlengthWs(thresh_spctrm, 'weighted'));
            updateWaitbar()
        end


    end
else
    updateWaitbar = waitbarParfor(length(spctrm)*length(chars), "Calculate characteristics...");
    strength = zeros(length(spctrm), length(T.freq{1}));
    SWP = zeros(length(spctrm), length(T.freq{1}));
    SW = zeros(length(spctrm), length(T.freq{1}));
    parfor i = 1:length(spctrm)
        try
            if ismember('strength', chars)
                strength(i,:) = nanmedian(bv_multisquareform(thresh_spctrm),2);
                updateWaitbar()
            end
            if ismember('SWP', chars)
                SWP(i,:) = gr_calculateSmallworldPropensityWs(thresh_spctrm);
                updateWaitbar()
            end
            if ismember('SW', chars)
                SW(i,:) = gr_calculateSmallWorldnessHumphries(thresh_spctrm, 1);
                updateWaitbar()
            end
        catch
            error('%1.0f: %s', i, lasterr)
        end

    end
end

if ismember('strength', chars)
    T.(strengthfield) = strength;
end
if ismember('SW', chars)
    T.(swfield) = SW;
end
if ismember('SWP', chars)
    T.(swpfield) = SWP;
end
if ismember('C', chars)
    T.(cfield) = C;
end
if ismember('L', chars)
    T.(lfield) = L;
end
if ismember('modularity', chars)
    T.(qfield) = Q;
end
if ismember('Lnrm', chars)
    T.(lnrmfield) = lambdas;
end