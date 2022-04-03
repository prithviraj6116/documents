function changed = replace_header(sourcefile,header_out,header_in)
% replaces_header - Changes the file name specified in a #include
%
% changed = realce_header(file_to_modify,header_to_remove,header_to_add);
%
if iscell(sourcefile)
    changed = false(size(sourcefile));
    for i=1:numel(sourcefile)
        try
            changed(i) = replace_header(sourcefile{i},header_out,header_in);
        catch E
            disp(E.message);
        end
    end
    return;
end

sf = mtfilename(sourcefile);
t = readtextfile(sf);

c = i_find_line(t,['#include ["<]' strrep(header_out,'/','\/') '[>"]']);
if isempty(c)
    % Not found.
    changed = false;
    return;
end

p4edit(sourcefile);

system_header = false;
if ~any(header_in=='.')
    system_header = true;
elseif ~isempty(regexp(header_in,'std.*.h\>','once'))
    system_header = true;
elseif ~isempty(regexp(header_in,'^boost\/','once'))
    system_header = true;
elseif strcmp(header_in,'string.h')
    system_header = true;
end
    
if ~system_header
    header_in = ['"' header_in '"'];
else
    header_in = ['<' header_in '>']; % system header
end
t{c} = ['#include ' header_in];

writetextfile(mtfilename(sourcefile),t);

fprintf('%s updated\n',sourcefile);

changed = true;

end

function n = i_find_line(t,exp)
    n = regexp(t,exp);
    n = find(~cellfun('isempty',n));
    if ~isempty(n)
        n = n(end);
    end
end