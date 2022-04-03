function headersubtree(filename,pattern,force)
% headersubtree - Prints any portions of the header tree for the specified
%       source file which match the supplied regular expression
%
% headersubtree(filename,pattern)
%
% e.g. headersubtree sl_obj/slobjprm.cpp \<util\.h

if nargin<3
    force = false;
end
if mt_endswith(filename,'_headertree')
    treefile = mtfilename(filename);
else
    treefile = mtfilename([filename '_headertree']);
    % Use the existing headertree file if it exists and is recent enough.
    if force || ~exist(treefile,'file') || ~newerthan(treefile,filename)
        headertree(filename);
    end
end
i_headertree(filename,treefile,pattern);

end

%----------------------------------------------------
function i_headertree(displayname,treefile,pattern)

fprintf('Header subtree for %s, matching : %s\n',displayname, pattern);

lines = readtextfile(treefile);
stack = java.util.Stack;

for count=1:numel(lines)
    t = lines{count};
    if isempty(t)
        continue;
    end
    
    [depth,filename] = i_parse(t);
    if depth>stack.size()
        % Inside previous file.  Add to stack.
        while depth-stack.size()>1
            stack.push('<unknown>');
        end
    elseif depth==stack.size()
        % Same level as previous file.  Replace the top item on the stack.
        stack.pop();
    else
        % Inside an earlier file.  Remove unnecessary stack entries.
        while stack.size()>depth
            stack.pop();
        end
        % Replace the top item on the stack.
        stack.pop();
    end
    stack.push(filename);
    if ~isempty(regexp(filename,pattern,'once'))
        print_stack(stack);
    end
    
end

end

function [depth,filename] = i_parse(filename)
    match = regexp(filename,'(?<dots>\. )*(?<filename>[^ ]*)','names');
    depth = numel(match.dots)/2;
    filename = match.filename;
end

function print_stack(stack)
    fprintf('\nMatch:\n');
    count = 0;
    for i=1:stack.size()
        f = char(stack.elementAt(i-1));
        if strncmp(f,'$derived/',9)
            % It's a derived header.  Check whether the next entry in the
            % stack is the corresponding exported header.
            if stack.size()>i
                p = char(stack.elementAt(i));
                f_mod = i_get_module(f);
                p_mod = i_get_module(p);
                if strcmp(f_mod,p_mod)
                    % Same module.  Skip it.
                    continue;
                end
            end
        end
        indent = repmat('. ',1,count);
        fprintf('%s%s\n',indent,f);
        count = count + 1;
    end
end

function m = i_get_module(f)
    t = regexp(f,'\$exp\/([^\/]*)/.*','tokens');
    if ~isempty(t)
        t = t{1};
        m = t{1};
        return;
    end
    t = regexp(f,'\$derived\/([^\/]*)/.*','tokens');
    if ~isempty(t)
        t = t{1};
        m = t{1};
        return;
    end
    m = '';
end
