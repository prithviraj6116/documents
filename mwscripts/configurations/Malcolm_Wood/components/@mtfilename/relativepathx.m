function c = relativepath(obj,directory)
%MTFILENAME/RELATIVEPATHX Returns the relative path to files
%
% c = relativepathx(obj,directory)
%
% c is a cell array of strings.

d = mtfilename(directory);
c = cell(size(obj));
for i=1:numel(obj)
    c{i} = relativepath(obj(i),d);
end

