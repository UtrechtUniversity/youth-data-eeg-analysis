function [ data  ] = bv_resampleEEGdata( cfg , data )
% bv_resampleEEGdata resamples eegdata either from disk or from memory.
% Uses FT_RESAMPLEDATA
%
% Use as:
%  [ data , oldSampleInfo ] = bv_resampleEEGdata( cfg , data )
%
% Possible inputs:
%   cfg:    structure with the following possible inputs:
%               cfg.resampleFs      = [ number ]: new sampling rate
%           if no data structure if given:
%               cfg.dataset         = 'string': filename of dataset
%               cfg.hdrfile         = 'string': filename of headerfile]
%
%   data: fieldtrip data structure
%
% Possible outputs:
%   data:           resampled data in fieldtrip data structure
%   oldSampleInfo:  vector of old sample info information mapped to newly
%                   resampled sampleinfo

resampleFs  = ft_getopt(cfg, 'resampleFs');
dataset     = ft_getopt(cfg, 'dataset');
hdrfile     = ft_getopt(cfg, 'hdrfile');

if nargin < 1
    
    if isempty(dataset)
        error('No dataset given')
    end
    if isempty(hdrfile)
        error('No hdrfile given')
    end
    
    fprintf('no data input detected, loading raw file ... ')
    
    cfg.dataset = dataset;
    cfg.hdrfile = hdrfile;
    
    data = ft_preprocessing(cfg);
    fprintf('done! \n')
end

% resample (with detrend)
fprintf('\t Resampling data from %s to %s ... ', num2str(data.fsample), num2str(resampleFs))
cfg = [];
cfg.resamplefs  = resampleFs;
% cfg.detrend     = 'yes';

evalc('data = ft_resampledata(cfg, data);');


% % correct poor resampling of first and last sampling indices
% sampleLine = data.trial{1}(end,:);
% incorrectResampleIndx = abs(diff(sampleLine)) > 2*2048/512;
% 
% incorrectResampleIndx = [1 incorrectResampleIndx+1];
% 
% for i = 1:length(incorrectResampleIndx)
%     data.trial{1}(end,incorrectResampleIndx(i)) = (incorrectResampleIndx(i)-1)*2048/512 + 1;
% end
% 
% oldSampleInfo = data.trial{1}(end,:); % save resampled sampling indices for later use.
% data.trial{1}(end,:) = []; % remove sample channel from data
% data.label(end) = [];

fprintf('done! \n')
