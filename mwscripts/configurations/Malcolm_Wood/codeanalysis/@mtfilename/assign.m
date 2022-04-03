function obj = assign(obj,name,type,assumedir)
%MTFILENAME/ASSIGN Private method
%
% obj = assign(obj,name,type,assumedir)

if length(obj)~=1
    error('mwood:tools:error','Exactly one object at a time, please');
end

if isempty(name)
    return; % stays empty
end

if nargin<3 || isempty(type)
    type = '?';
end
if nargin<4
    assumedir = 0;
end


if strcmp(type,'?')
    % Try to work out the type
    [p,~,e] = fileparts(name);
    if isempty(p)
        if isempty(e)
            % command or subdirectory of pwd
            obj.absname = [pwd filesep name];
            if assumedir || exist(obj.absname,'dir')==7 % directory
                obj.isdir = 1;
            else
                obj.command = name;
                if ~isempty(name)
                    % This may be empty if the command is not found
                    obj.absname = which(name);
                end
            end
        else
            % relative (and in this directory)
            obj.absname = [pwd filesep name];
            obj.dirpath = mtfilename(pwd,'abs',1); % assume directory
            if assumedir || isempty(e)
                obj.isdir = 1;
            end
        end
    else
        if name(1)==filesep
            if length(name)>1 && name(2)==filesep
                % network path (on Windows)
                obj.absname = name;
            elseif ispc
                error('mwood:tools:mtfilename','Filenames beginning with a single separator are not supported on Windows');
            else
                obj.absname = name;
            end
            if assumedir || isempty(e)
                obj.isdir = 1;
            end
        else
            if length(name)>1 && name(2)==':'
                % absolute on a named (Windows) drive
                obj.absname = name;
            else
                % relative (but in another directory)
                obj.absname = [pwd filesep name];
            end
            if assumedir || isempty(e)
                obj.isdir = 1;
            end
        end
    end
else
    % We know the type.  Find the full name
    switch type
    case 'abs'
        obj.absname = name;
        if assumedir || isdir(obj.absname)
            obj.isdir = 1;
        end
    case 'rel'
        obj.absname = [pwd filesep name];
        if assumedir || isdir(obj.absname)
            obj.isdir = 1;
        end
    case 'command'
        obj.command = name;
        if ~isempty(name)
            % This may be empty if the command is not found
            obj.absname = mt_which(name);
        end
    otherwise
        error('mwood:tools:error',['Unknown filename type: ' type]);
    end
end

if obj.isdir && obj.absname(end)==filesep
    obj.absname(end) = [];
end
