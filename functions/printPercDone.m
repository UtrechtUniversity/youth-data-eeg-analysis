function lng = printPercDone(n, i)

percString = num2str(round((i/(n))*100,2));
lng = fprintf('%s %%', percString);