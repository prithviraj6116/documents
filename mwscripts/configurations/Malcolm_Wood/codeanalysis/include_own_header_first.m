function include_own_header_first(src)
% Moves a file's own header to the top of its #include list
%
% include_own_header_first(sourcefile)
%
% For a file X.cpp, the lines:
%  #include "version.h"
%  #include "X.hpp" 
% are inserted at the top of the file, and removed from anywhere else in
% the file.

src = relativepath(mtfilename(src),pwd);

[h,own_inc] = locate_own_header(src);
if isempty(h)
    own_inc = '<not found>';
end

inc = included_headers_in_file(src);
if strcmp(inc{1},'version.h')
    if strcmp(inc{2},own_inc)
        fprintf('OK: %s\n',src);
        return;
    end
end

r = remove_header(src,own_inc);
if ~r
    [d,n] = slfileparts(src);
    r = remove_header(src,[d '/' n '.hpp']);
    if ~r
        warning('mwood:tools:headers','Didn''t find inclusion of own header');
    end
end

remove_header(src,'version.h');

sf = mtfilename(src);
t = readtextfile(sf);

first_include = i_find_line(t,'#include');
if isempty(first_include)
    first_include = 1;
end

if ~isempty(h)
    newlines = sprintf('#include "version.h"\n\n#include "%s"\n\n',own_inc);
else
    newlines = sprintf('#include "version.h"\n\n');
end

t = [ t(1:first_include-1) ; {newlines} ; t(first_include:end) ];

p4edit(src);

writetextfile(sf,t);


end

function n = i_find_line(t,exp)
    n = regexp(t,exp);
    n = find(~cellfun('isempty',n));
    if ~isempty(n)
        n = n(1);
    end
end