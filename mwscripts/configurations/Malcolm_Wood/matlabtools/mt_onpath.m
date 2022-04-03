function onpath = mt_onpath(p,currentpath)
%MT_ONPATH Determines whether a given directory is on the MATLAB path
%
% onpath = mt_onpath(p)
%
% "p" can be a string or a cell array of strings.  The return value
% is a logical array.

if nargin<2
    currentpath = [ pathsep lower(path) pathsep ];
end

p = mt_ensurecell(p);
onpath = zeros(size(p));

for i=1:numel(p)
    if isa(p{i},'mtfilename')
        p{i} = getabs(p{i});
    end
    % Look for the entry with a leading and trailing semi-colon so that
    % we don't pick up substrings of the path entry.
    ind = strfind( currentpath, [ pathsep lower(p{i}) pathsep ] );
    onpath(i) = ~isempty( ind );
end
onpath = logical(onpath);
