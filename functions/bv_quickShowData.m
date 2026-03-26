function bv_quickShowData(data, preproc)

if nargin < 2
    preproc = [];
end

cfg = [];

cfg.viewmode = 'vertical';
cfg.ylim = [-100 100];
cfg.blocksize = 10;
cfg.continuous = 'yes';
cfg.preproc = preproc;
ft_databrowser(cfg, data);