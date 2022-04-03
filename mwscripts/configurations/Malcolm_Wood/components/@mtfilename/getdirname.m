function dirname = getdirname(obj)
%GETDIRNAME - Returns the name of a directory as a string
%
% dirname = getdirname(obj)
%
% The specified mtfilename instance must represent a directory, not
% a file.

assert(length(obj)==1,'Exactly one object required');
if ~obj.isdir
    error('mwood:tools:getdirname',[ obj.absname ' is not a directory']);
end
[~,dirname] = fileparts(obj.absname);

