function strct = bv_log2struct(log)

fidlog = fopen(log, 'r');

while 1
    line = fgetl(fidlog);
    
    if line==-1
        break
    end
    
    if not(strcmp(line(1), '*'))
        splitline = strsplit(line, ', ');
        strct.(splitline{1}) = splitline{2};
    end
end


