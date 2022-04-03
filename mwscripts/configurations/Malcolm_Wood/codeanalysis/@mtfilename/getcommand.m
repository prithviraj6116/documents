function [command,obj] = getcommand(obj)
%MTFILENAME/GETCOMMAND Returns the "command" part of this filename as a string
%
%  [command,obj] = getcommand(obj)
%

assert(length(obj)==1,'Exactly one object required');
if obj.isdir
    error('mwood:tools:mtfilename',[obj.absname ' is a directory']);
end
if isempty(obj.command)
    [dp, obj.command, obj.extension] = fileparts(obj.absname);
    obj.dirpath = mtfilename(dp,'abs',1); % assume directory
end
command = obj.command;

