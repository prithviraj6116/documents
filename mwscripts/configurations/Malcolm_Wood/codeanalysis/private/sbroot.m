function r = sbroot(name)
% Gets the current sandbox root.  Does not assume that MATLAB is running
% from this sandbox, so not necessarily related to matlabroot.
%
% root = sbroot % relative to current folder
% root = sbroot(filename) % relative to specified file or folder

persistent lastroot;

if ~nargin
    filename = mtfilename(pwd);
else
    filename = mtfilename(name);
    if ~isdir(filename)
        filename = parentdir(filename);
    end
end

r = getabs(filename);
if ~isempty(lastroot) && strncmp(r,lastroot,numel(lastroot))
    r = lastroot;
    return;
end

while ~is_sbroot_folder(r)
    if isempty(strfind(r,'matlab'))
        error('mwood:tools:mod','sbroot not found: %s',getabs(filename));
    end            
    r = fileparts(r);
end
lastroot = r; % cache for next time

end

function b = is_sbroot_folder(d)
    b = exist(fullfile(d,'mw_anchor'),'file') ~= 0;
end
