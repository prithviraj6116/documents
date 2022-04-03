function out = matchext(obj,ext)
%MTFILENAME/MATCHEXT
%
% out = matchext(obj,ext)
%

assert(ischar(ext),'Extension must be a string');
assert(ext(1)=='.','Valid extension starts with a dot');
e = getextensionx(obj);
out = strcmpi(e,ext);

