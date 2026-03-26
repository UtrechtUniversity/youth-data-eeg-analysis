function [zs,xmu,xsigma] = bv_nanZScore(X,dim)

if nargin < 2
    if isvector(X)
        dim = find(size(X)>1);
    else
        error('missing dim input')
    end
end

if any(isnan(X(:)))
    xmu=nanmean(X,dim);
    xsigma=nanstd(X,[],dim);
    switch dim
        case 1
            zs=(X-repmat(xmu,length(X),1))./repmat(xsigma,length(X),1);
        case 2
            zs=(X-repmat(xmu,1,length(X)))./repmat(xsigma,1, length(X));
        otherwise
            error('Max dims = 2')
    end            
else
    [zs,xmu,xsigma]=zscore(X);
end