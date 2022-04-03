function r = sbroot(name)
% Gets the current sandbox root.  Does not assume that MATLAB is running
% from this sandbox, so not necessarily related to matlabroot.
%
% root = sbroot % relative to current folder
% root = sbroot(filename) % relative to specified file or folder

if ~nargin
    filename = mtfilename(pwd);
else
    filename = mtfilename(name);
end
if ~isdir(filename)
    filename = parentdir(filename);
end

r = getabs(filename);
while ~is_sbroot_folder(r)
    if isempty(strfind(r,'matlab'))
        error('mwood:tools:mod','sbroot not found: %s',getabs(filename));
    end            
    r = fileparts(r);
end
end

function b = is_sbroot_folder(d)
    b = exist(fullfile(d,'mw_anchor'),'file') ~= 0;
end
