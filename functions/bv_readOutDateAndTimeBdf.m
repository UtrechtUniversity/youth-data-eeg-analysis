function [date, time] = bv_readOutDateAndTimeBdf(bdffile)


fid = fopen(bdffile, 'r');
expr = '[0-3][0-9].[0-1][0-9].[0-9][0-9][0-2][0-9].[0-5][0-9].[0-5][0-9]';

while 1
    currWord = fgetl(fid);
    
    datetimestr = regexp(currWord, expr,'match');
    
    if ~isempty(datetimestr)
        splitdateandtime = strsplit(datetimestr{1}, '.');
        date = [splitdateandtime{1} '-' splitdateandtime{2} '-' splitdateandtime{3}(1:2)];
        time = [splitdateandtime{3}(3:4) ':' splitdateandtime{4} ':' splitdateandtime{5}(1:2)];
        break
    end
end
    
fclose all;