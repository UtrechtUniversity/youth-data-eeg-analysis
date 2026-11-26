function lng = printPercDone(n, i)
% Prints a progress percentage to the command window.
%
% Prints ``i`` out of ``n`` as a percentage rounded to two decimals (e.g.
% ``12.5 %``) without a newline, and returns the number of characters
% printed so the caller can erase it again before printing the next value.
%
% Args:
%     n (numeric): Total number of steps. Must be greater than 0.
%     i (numeric): Number of steps completed so far.
%
% Returns:
%     lng (numeric): Number of characters printed, to be passed to
%         ``fprintf(repmat('\b', 1, lng))`` to erase the percentage.
%
% Example:
%     ```matlab
%     for i = 1:n
%         lng = printPercDone(n, i);
%         % ... do the work ...
%         fprintf(repmat('\b', 1, lng))
%     end
%     ```

if n <= 0
    error('printPercDone: n must be greater than 0, got %g', n)
end

percString = num2str(round((i/(n))*100,2));
lng = fprintf('%s %%', percString);
