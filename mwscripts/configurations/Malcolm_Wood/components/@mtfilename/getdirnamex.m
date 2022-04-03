function dirname = getdirnamex(obj)
%GETDIRNAME - Returns the name of directories as a cell array of strings
%
% dirnames = getdirnamex(obj)
%
% The specified mtfilename instances must represent directories, not
% files.

if numel(obj)==0
    dirname= {};
    return;
end
dirname = cell(size(obj));
for i=1:numel(obj)
    [~,dirname{i}] = dirname(obj(i));
end
