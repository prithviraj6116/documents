function headers = included_headers_in_file(sourcefile)
% Returns the contents of all #include lines in the specified file
%
% headers = included_headers_in_file(sourcefile)
%
% "headers" is a cell array of strings, in exactly the form that they
% appear in the source file.

sf = mtfilename(sourcefile);
t = readtextfile(sf);

m = regexp(t,'#include [<"](?<header>.*)[">]','names');
m = [m{:}];
if ~isempty(m)
    headers = {m.header}';
else
    headers = {};
end