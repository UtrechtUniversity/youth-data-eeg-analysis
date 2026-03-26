function [data] = bv_filterEEGdata(cfg, data)
% bv_filterEEGdata is a helper function to filter either input eeg data 
% (arg2) or a raw eeg dataset given as cfg.dataset. Uses FT_PREPROCESSING
%
% Use as
%  [ data ] = bv_filterEEGdata( cfg , data )
%
% Possible fields of configuration structure:
%   cfg.hpfreq      = [ number ]: high-pass cut-off frequency
%   cfg.lpfreq      = [ number ]: low-pass cut-off frequency
%   cfg.notchfreq   = [ number ]: notch filter frequency
%   cfg.filttype    = 'string' ('but' or 'firws'): type of filter (default:
%                       'but')
%
% If no input dataset is given:
%   cfg.dataset     = 'string': name of dataset
%   cfg.hdrfile     = 'string': name of hdrfile
%
% See also FT_PREPROCESSING

dataset     = ft_getopt(cfg, 'dataset');
hdrfile     = ft_getopt(cfg, 'hdrfile');
hpfreq      = ft_getopt(cfg, 'hpfreq');
lpfreq      = ft_getopt(cfg, 'lpfreq');
notchfreq   = ft_getopt(cfg, 'notchfreq');
filttype    = ft_getopt(cfg, 'filttype');

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

fprintf('\t Filtering data  ... \n')
fprintf('\t\t')
cfg = []; % create new configuration structure
if ~isempty(hpfreq) % high-pass filter configuration
    cfg.hpfilter            = 'yes';
    cfg.hpfreq              = hpfreq;
    cfg.hpfilttype          = filttype;
    cfg.hpinstabilityfix    = 'reduce'; % set to overcome problems with filter order
    
    fprintf('hpfilter: %1.1f ', hpfreq)
    
    if strcmpi(filttype, 'firws')
        cfg.hpfiltord  = floor(2048*4.8);
    end
end
if ~isempty(lpfreq) % low-pass filter configuration
    cfg.lpfilter            = 'yes';
    cfg.lpfreq              = lpfreq;
    cfg.lpfilttype          = filttype;
    cfg.lpinstabilityfix    = 'reduce';
    
    fprintf('lpfilter: %1.1f ', lpfreq)
    
    if strcmpi(filttype, 'firws')
        cfg.hpfiltord  = floor(2048*4.8);
    end
end

if ~isempty(notchfreq) % notch filter configuration
    % create a notchfilter for all the resonance frequencies of given notch
    % filter. The notch filter is created as a bandstop filter with the two
    % limits chosen as the given notchfreq +/- 2
    maxFreq         = data.fsample / 2;
    
    for i = 1: (maxFreq / notchfreq)
        bsFreq(i,:) = [notchfreq*i - 2, notchfreq*i + 2];
    end
    
    fprintf('notchfilter: %1.1f ', notchfreq)
    
    cfg.bsfilter            = 'yes';
    cfg.bsfreq              = bsFreq;
    cfg.bsfilttype          = 'but';
    cfg.bsinstabilityfix    = 'reduce';
    
    if strcmpi(filttype, 'firws')
        cfg.bsfiltord  = floor(2048*4.8);
    end
    
end

cfg.padding = 10; % set padding to limit edge effects of filter (not really important if you load in continuous data) 

evalc('data = ft_preprocessing(cfg, data);');
fprintf('done! \n')