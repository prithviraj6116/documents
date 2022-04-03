function out = exist(obj,~)
%MTFILENAME/EXIST
%
% out = exist(obj)
%
% Simpler than the built-in "exist" in that the return
% value is logical rather than integral.
% The return value is false if a file with the specified name
% exists, but the object specifies a directory, and vice versa.
%

if length(obj)==0
    out = logical([]);
else
    out = zeros(size(obj));
    dirs = isdir(obj);
    for i=1:length(obj)
        if dirs(i)
            out(i) = exist(obj(i).absname)~=0;
        else
            out(i) = exist(obj(i).absname,'file')~=0;
        end
    end
    out = logical(out~=0);
end

