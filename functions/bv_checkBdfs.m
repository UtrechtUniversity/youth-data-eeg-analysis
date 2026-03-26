bdfs = dir('*.bdf');
bdfnames = {bdfs.name};
cMax = length(bdfnames);
counter = 0;
percStr = [];

for i = 1:length(bdfnames)
%     err = 0;
    try
        event = ft_read_event(bdfnames{i});
    catch
        disp(bdfnames{i})
        fprintf('\t %s \n', lasterr)
%         err = 1;
    end

    
%     if i~=1 && ~err
%         fprintf(repmat('\b',1,length(percStr)))
%     end
%     
%     counter = counter + 1;
%     percDone = (counter./cMax).*100;
%     percStr = [num2str(percDone) '%'];
%     
%     fprintf('%s', percStr)
end

fprintf('\n')
        