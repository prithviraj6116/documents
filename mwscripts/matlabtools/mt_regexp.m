function b = mt_regexp(str,pattern)
% mt_regexp - regexp for a cellstr, returning a logical array
%
%  b = mt_regexp(cellstr,pattern)
%
% Each element in b is true if the corresponding string in cellstr matches
% the supplied pattern.

m = regexp(str,pattern);
b = ~cellfun('isempty',m);

end