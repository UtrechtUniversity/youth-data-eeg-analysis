function mat = bv_quickShowMatrix(str, filestr, number, tit)

if nargin < 4
    tit = '';
end

connectivity = bv_quickloadData(str, filestr);
mat = connectivity.plispctrm(:,:,number);
figure; imagesc(mat);
bv_autoCorrSettings(gca, connectivity.label)
title(tit)


