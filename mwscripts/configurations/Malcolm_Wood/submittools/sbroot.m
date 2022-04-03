function root = sbroot(name)
% Gets the current sandbox root.  Does not assume that MATLAB is running
% from this sandbox, so not necessarily related to matlabroot.
%
% root = sbroot % relative to current folder
% root = sbroot(filename) % relative to specified file or folder

if ~nargin || isempty(name)
    name = pwd;
end
folder = Simulink.loadsave.resolveFolder(name);
if isempty(folder)
    file = Simulink.loadsave.resolveFile(name);
    if ~isempty(file)
        folder = slfileparts(file);
    end
end

% Calling the real "sbroot" can be annoyingly slow
%if exist(getabs(filename),'file') && ~isdir(filename)
%    filename = parentdir(filename);
%end
% if ispc
%     sep = ' && ';
% else
%     sep = ';';
% end
% [status,output] = system(sprintf('cd %s%ssbroot',getabs(filename),sep));
% root = output(output~=char(10));
% if status==0 && exist(root,'dir')
%     return;
% else
%     error('mwood:tools:sbroot','Not in a sandbox: %s', output);
% end

% Old implementation follows


% First, if we're inside matlabroot for a sandbox, identify the root
% level in the folder hierarchy.
match = regexp(folder,'(?<sbroot>^.*\/matlab)(\/.*)*$','names');
if ~isempty(match)
    % Good found it.
    folder = slfileparts(match.sbroot);
end

% "matlab" folder not found, but it's possible that this is the sbroot
% itself, or a subfolder of it.
% Look for a folder called "matlab" inside this one, and also a file
% called "mw_anchor"
while true
    if i_matlab_folder_exists(folder) && i_battree_file_exists(folder)
        root = folder;
        return;
    else
        newdir = slfileparts(folder);
        if strcmp(newdir,folder)
            error('mwood:tools:sbroot','Not in a sandbox');
        else
            folder = newdir;
        end
    end
end
end

function e = i_matlab_folder_exists(f)
    e = ~isempty(Simulink.loadsave.resolveFolder(slfullfile(f,'matlab')));
end

function e = i_battree_file_exists(f)
    e = ~isempty(Simulink.loadsave.resolveFile(slfullfile(f,'mw_anchor')));
end
