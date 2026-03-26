function out = bv_getNumbers(in)

nos = regexp(in, '\d*\.?\d*', 'Match');
out = sscanf(sprintf('%s', cat(2,nos{:})), '%f');
