function [extension,obj] = getextensionx(obj)
%MTFILENAME/GETEXTENSIONX Returns the extension part of this filename as a cell array
%
%  [extension,obj] = getextensionx(obj)
%

extension = cell(size(obj));
for i=1:length(obj)
    [extension{i},obj(i)] = getextension(obj(i));
end

