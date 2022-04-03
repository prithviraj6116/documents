function [d,c,e,obj] = fileparts(obj)
%MTFILENAME/FILEPARTS Splits the filename into parts
%
% [d,c,e,obj] = fileparts(obj)
%
% d is the directory (as a string)
% c is the "command" part of the filename
% e is the extension, including the dot
%
%
% See built-in FILEPARTS
%

assert(length(obj)==1,'Exactly one object required');
if ~obj.isdir
    if isempty(obj.command) || isempty(obj.dirpath) || isempty(obj.extension)
        [d, obj.command, obj.extension] = fileparts(obj.absname);
        obj.dirpath = mtfilename(d,'abs',1); % assume directory
    end
    d = getabs(obj.dirpath);
else
    [d,obj] = parentdir(obj);
end
c = obj.command;
e = obj.extension;

