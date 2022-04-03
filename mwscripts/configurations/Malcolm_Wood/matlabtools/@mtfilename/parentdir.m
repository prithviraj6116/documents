function [dirpath,obj] = parentdir(obj)
%MTFILENAME/PARENTDIR
%
% [dirpath,obj] = parentdir(obj)
%
% Returns mtfilename of size(obj)
%
dirpath = mtfilename(size(obj));
for i=1:length(obj)
    if isempty(obj(i).dirpath)
        [dp,obj(i).command,obj(i).extension] = fileparts(obj(i).absname);
        obj(i).dirpath = mtfilename(dp,'abs',1); % assume directory
    end
    dirpath(i) = obj(i).dirpath;
end

