function [ext,obj] = getextension(obj)
%MTFILENAME/GETEXTENSION
%
% [ext,obj] = getextension(obj)
%

assert(length(obj)==1,'Exactly one object required');
if isempty(obj.extension) && ~obj.isdir
    [dp, obj.command, obj.extension] = fileparts(obj.absname);
    obj.dirpath = mtfilename(dp,'abs',1); % assume directory
end
ext = obj.extension;

