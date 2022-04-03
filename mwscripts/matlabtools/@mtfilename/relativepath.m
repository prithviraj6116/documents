function str = relativepath(obj,directory)
%MTFILENAME/RELATIVEPATH Returns the relative path to a file
%
% str = relativepath(obj,directory)
%
% str is a string.

assert(numel(obj)==1,'Exactly one object required');
d = mtfilename(directory);

assert(isindirectory(obj,d),'File must be inside directory');

n = numel(d.absname);
str = obj.absname(n+2:end); % strip leading separator

