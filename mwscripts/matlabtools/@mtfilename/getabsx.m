function [absname,obj] = getabsx(obj)
%MTFILENAME/GETABSX Returns the absolute filename as a cell array
%
%  [absname,obj] = getabsx(obj)
%

if length(obj)==0
    absname = {};
else
    absname = { obj.absname };
    absname = reshape(absname,size(obj));
end


