function [modules,relative] = find_module_folder(files)
% All modules and files must be relative to sbroot.
r = sbroot;
restore = mt_cd(r);

modules = files;
relative = files;
if ischar(files)
    [modules,relative] = i_find_module_folder(files);
elseif iscell(files)
    for i=1:numel(files)
        [modules{i},relative{i}] = i_find_module_folder(files{i});
    end
else
    % Assume mtfilename objects
    relative = cell(size(files));
    for i=1:numel(files)
        [m,r] = i_find_module_folder(getabs(files(i)));
        modules(i) = mtfilename(m);
        relative{i} = r;
    end
end

delete(restore);

end

function [d,r] = i_find_module_folder(f)
    [d,n,e] = fileparts(f);
    r = [n e];
    while ~is_module_folder(d)
        [d,n] = fileparts(d);
        r = [n '/' r]; %#ok<AGROW>
        if mt_endswith(n,'matlab/src') || mt_endswith(n,'matlab/toolbox')
            error('mwood:tools:mod','Module folder not found: %s',f);
        end            
    end
end

function b = is_module_folder(d)
    b = exist(fullfile(d,'MODULE_DEPENDENCIES'),'file') ~= 0;
end
