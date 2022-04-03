function varargout = char(obj)
%MTFILENAME/CHAR

if isempty(obj)
    varargout = {};
else
    c = {obj.absname};
    e = cellfun('isempty',c);
    if any(e)
        c(e) = {obj(e).command};
    end
    varargout = c;
end


