function [command,obj] = getcommandx(obj)
%MTFILENAME/GETCOMMANDX Returns the "command" part of this filename as a cell array
%
%  [command,obj] = getcommandx(obj)
%

command = cell(size(obj));
for i=1:length(obj)
    [command{i},obj(i)] = getcommand(obj(i));
end

