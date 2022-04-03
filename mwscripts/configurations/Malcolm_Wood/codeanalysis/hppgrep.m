function files = hppgrep(str)
% hppgrep - Search .hpp files in the current folder and its subfolders
%
% Returns a list of files which contain the supplied regular expression.

files = cppgrep(str,'hpp');