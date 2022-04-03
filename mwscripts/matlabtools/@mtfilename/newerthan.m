function newer = newerthan(obj,second)
%SFILENAME/NEWERTHAN
%
% newer = newerthan(obj, other)
%
% Returns true if the first file is newer than the second file.  It is an
% error to specify multiple files in either input, or files which do not
% exist.

obj = mtfilename(obj);
second = mtfilename(second);
%assert(exist(obj,'file'),'File must exist');
assert(exist(second,'file'),'File must exist');
d1 = dir(getabs(obj));
d2 = dir(getabs(second));
newer = d1.datenum>d2.datenum;
