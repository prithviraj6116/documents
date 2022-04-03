function sorted_headers = sortheaders(headers,modname)

% Sort such that upstream headers are first.
sorted_headers = cell(size(headers));
for i=1:numel(headers)
  [sorted_headers{i},ind] = i_find_next(headers,modname,false);
  headers{ind} = '';
  disp(sorted_headers{i});
end

writetextfile(mtfilename('headerlist.txt'),headers);
end

% Returns a header from the list which doesn't include any other header in
% the list.
function [h,ind] = i_find_next(headers,modname,verbose)
    % This is a very blunt approach!
    for i=1:numel(headers)
        if isempty(headers{i})
            continue;
        end
        t = readtextfile(mtfilename(fullfile(pwd,headers{i})),true);
        top_level = true;
        for k=1:numel(headers)
            if k==i
                continue;
            end
            if isempty(headers{k})
                continue;
            end
            if i_includes(t,headers{k},modname)
                if nargin>3 && verbose
                    fprintf('%s depends on %s\n',headers{i},headers{k});
                end
                top_level = false;
                break;
            end
        end
        if top_level
            h = headers{i};
            ind = i;
            return;
        end
    end
    i_find_next(headers,modname,true)
    assert(false,'Couldn''t find a header without dependencies');
end


function b = i_includes(t,name,modname)
    [~,n,e] = fileparts(name);
    shortname = [n '\' e];
    b = ~isempty(regexp(t,shortname,'once'));
    if (b)
        % The shortname appears in the file.  But we need to make sure that
        % either there's no module specified or it's *this* module
        regname = strrep(name,'/','\/');
        b2 = ~isempty(regexp(t,['#include.*' modname '\/' regname],'once'));
        if b2
            % Yes.  This module specified.
            return;
        end
        b2 = ~isempty(regexp(t,['#include.*'  '"' regname],'once'));
        if b2
            % Yes.  No module specified.
            return;
        end
        b2 = ~isempty(regexp(t,['#include.*' '"' shortname],'once'));
        if b2
            % Yes.  No module specified.
            return;
        end
        b = false; % could be a different relative path, but more likely to be in another module.
    end
end
