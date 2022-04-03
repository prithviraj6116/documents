function [shortname,obj] = getshortname(obj)
%MTFILENAME/GETSHORTNAME Returns the name (without path) of this file as a string
%
%  [shortname,obj] = getshortname(obj)
%

assert(length(obj)==1,'Exactly one object required');
if obj.isdir
    error('mwood:tools:mtfilename',[obj.absname ' is a directory']);
end
if isempty(obj.command) || isempty(obj.extension)
    [dp, obj.command, obj.extension] = fileparts(obj.absname);
    obj.dirpath = mtfilename(dp,'abs',1); % assume directory
end
shortname = [obj.command obj.extension];

