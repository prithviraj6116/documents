function varargout = mt_fileparts(f)

persistent got_slfileparts;
if isempty(got_slfileparts)
    got_slfileparts = ~isempty(which('slfileparts'));
end

if got_slfileparts
    [varargout{1:nargout}] = slfileparts(f);
else
    [varargout{1:nargout}] = fileparts(f);
end