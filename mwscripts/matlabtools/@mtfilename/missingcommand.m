function out = missingcommand(obj)
%MTFILENAME/MISSINGCOMMAND
% Returns true for any file for which the absname is empty but the
% command is not.

% 
out = zeros(size(obj));
for i=1:length(obj)
    out(i) = isempty(obj(i).absname) & ~isempty(obj(i).command);
end


