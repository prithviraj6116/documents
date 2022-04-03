function p = mt_sortedpath(pattern)
% Returns the current MATLAB path, sorted alphabetically
% and case-insensitively.  Optionally returns only entries matching
% the supplied expression.

fullpath = path;
p = textscan(fullpath,'%s','delimiter',pathsep);
p = p{1};
pl = lower(p);
[~,i] = sort(pl);
p = p(i);

if nargin && ~isempty(pattern)
    match = regexp(p,pattern);
    match = ~cellfun('isempty',match);
    p = p(match);
end
