function absname = getabs(obj)
%MTFILENAME/GETABS Returns the absolute filename as a string
%
%  [absname,obj] = getabs(obj)
%

assert(length(obj)==1,'Exactly one object required');
absname = obj.absname;

