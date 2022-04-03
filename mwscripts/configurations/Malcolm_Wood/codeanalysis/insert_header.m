function inserted = insert_header(sourcefile,header,comment,after,target)
% insert_header - Inserts a #include for a specified header
%
% inserted = insert_header(file_to_modify,header_to_include);
% inserted = insert_header(file_to_modify,header_to_include,comment,after);
% inserted = insert_header(file_to_modify,header_to_include,comment);
%
% file_to_modify - string or cellstr; the file(s) in which to insert the #include
% header - string; the relative path to the header to be #included
% after - string; the header after which to insert the new one
%
% A new #include will be added in as suitable a place as possible in the
% specified file - immediately after other #includes from the same module
% if possible, and otherwise after all #includes in the file.
%
% If "after" is specified, it must be present in the file being modified,
% otherwise a warning will be issued and no change will be made.
%
% file_to_modify should either be absolute or specified relative to pwd.

if nargin<4
    after = '';
end
if nargin<3
    comment = '';
end

if iscell(sourcefile)
    inserted = false(size(sourcefile));
    for i=1:numel(sourcefile)
        try
            inserted(i) = insert_header(sourcefile{i},header,comment,after);
        catch E
            disp(E.message);
        end
    end
    return;
end

fprintf('insert_header: %s  in   %s\n',header,sourcefile);

headerdir = strrep(fileparts(header),'/','\/');
headermod = strtok(header,'/');

sf = mtfilename(sourcefile);
t = readtextfile(sf);

c = i_find_line(t,['#include ["<]' strrep(header,'/','\/') '[>"]']);
if ~isempty(c)
    % Already present.
    inserted = false;
    return;
end

include_empty_line = '';
if nargin>3 && ~isempty(after)
    n = i_find_line(t,['#include "' after]);
else
    n = i_find_line(t,['#include "' headerdir]);
    if isempty(n)
        n = i_find_line(t,['#include "' headermod]);
    end
    if isempty(n)
        n = i_find_line(t,'#include "');
    end
    if isempty(n)
        n = i_find_line(t,'#include "');
    end
    if isempty(n)
        n = i_find_line(t,'#include <');
    end
    if isempty(n)
        [~,~,e] = fileparts(sourcefile);
        if strcmp(e,'.hpp')
            % A header file with no existing #includes
            n = regexp(t,'#define');
            n = find(~cellfun('isempty',n));
            if ~isempty(n)
                % first #define.  i_find_line returns *lst*
                n = n(1);
            end
            include_empty_line = sprintf('\n');
        end
    end
end

if isempty(n)
    warning('mwood:tools:insert_header','Can''t find suitable place to insert #include')
    inserted = false;
    return;
end

if nargin<5 || strcmp(sourcefile,target)
    % Target same as source file
    p4edit(sourcefile);
    target = sourcefile;
end

if nargin<3 || ~ischar(comment)
    comment = '';
end

if ischar(comment) && ~isempty(comment)
    comment = [' // ' comment];
end

system_header = false;
if ~any(header=='.')
    system_header = true;
elseif ~isempty(regexp(header,'std.*.h\>','once'))
    system_header = true;
elseif ~isempty(regexp(header,'^boost\/','once'))
    system_header = true;
elseif strcmp(header,'string.h')
    system_header = true;
end
    
if ~system_header
    header = ['"' header '"'];
else
    header = ['<' header '>']; % system header
end
insert = [include_empty_line '#include ' header comment];

t = [ t(1:n) ; {insert} ; t(n+1:end) ];
writetextfile(mtfilename(target),t);

fprintf('%s\n   Inserted line: %s\n',target,insert);

inserted = true;

end

function n = i_find_line(t,exp)
    n = regexp(t,exp);
    n = find(~cellfun('isempty',n));
    if ~isempty(n)
        n = n(end);
    end
end