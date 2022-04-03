function out = isdir(obj)
%MTFILENAME/ISDIR
%
% out = isdir(obj)
%

if length(obj)==0
    out = [];
else
    out = logical([obj.isdir]);
end

