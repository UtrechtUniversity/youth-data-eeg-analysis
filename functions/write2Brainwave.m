trialdata = [dataFiltTrls.trial{:}];
formatSpec = [repmat('%f \t ', 1, size(trialdata,1)) '\n'];
fid = fopen(['RS1.txt'], 'w');
fprintf(fid, formatSpec, trialdata);
fclose( 'all' );