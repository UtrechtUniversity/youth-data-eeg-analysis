function nLines = bv_determineLineCount(fid)

nLines = 0;
while 1
    nxtline = fgetl(fid);
    if nxtline == -1
        return
    else
        nLines = nLines + 1;
    end
end