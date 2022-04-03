function [out,ind] = ismember(f1,f2)
%MTFILENAME/ISMEMBER True for a member of a set of files
%
% [out,ind] = ismember(f1,f2)

f1 = getabsx(f1);
f2 = getabsx(f2);
[out,ind] = ismember(f1,f2);

