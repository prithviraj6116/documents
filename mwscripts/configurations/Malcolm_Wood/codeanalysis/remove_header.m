function removed = remove_header(sourcefile,header,target)
% remove_header
%
% removed = remove_header(sourcefile,header)
% removed = remove_header(sourcefile,header,target)
%

if iscell(sourcefile)
    if nargin>2
        error('mwood:tools:remove_header','Can''t specify targets with multiple files');
    end
    removed = false(size(sourcefile));
    for i=1:numel(sourcefile)
        removed(i) = remove_header(sourcefile{i},header);
    end
    return;
end

sf = mtfilename(sourcefile);
t = readtextfile(sf);

c =i_find_line(t,['#include "' strrep(header,'/','\/') '"']);
if isempty(c)
    c =i_find_line(t,['#include <' strrep(header,'/','\/') '>']);
    if isempty(c)
        % Not found.
        removed = false;
        return;
    end
end

if nargin<3 || strcmp(sourcefile,target)
    % Target same as source file
    p4edit(sourcefile);
    target = sourcefile;
end

t(c) = [];
writetextfile(mtfilename(target),t);

removed = true;

end

function n = i_find_line(t,exp)
    n = regexp(t,exp);
    n = find(~cellfun('isempty',n));
    if ~isempty(n)
        n = n(end);
    end
end
