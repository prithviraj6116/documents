function [shortname,obj] = getshortnamex(obj)
%MTFILENAME/GETSHORTNAMEX Returns the "shortname" of this filename as a cell array
%
%  [shortname,obj] = getshortnamex(obj)
%

shortname = cell(size(obj));
for i=1:length(obj)
    [shortname{i},obj(i)] = getshortname(obj(i));
end
