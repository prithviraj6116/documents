function obj = mtfilename(name,type,assumedir)
%MTFILENAME
%
% obj = mtfilename(name,type)
% obj = mtfilename(name,type,assumedir)
%
% type is one of:
%   rel, abs, command
%
% If multiple filenames are given, type must be a single string.
% If a command is given, it must be to an existing file on the
% MATLAB path.
% If assumedir is supplied and non-zero, the supplied name will be
% assumed to be a directory.  Otherwise, it will only be recognised
% as a directory if it exists.

if nargin==0
    name = 0;
end

if isa(name,'mtfilename')
    obj = name; % effectively a copy constructor
    return;
end

if nargin<2 || isempty(type)
    type = '?';
end
if nargin<3
    assumedir = 0;
end

if ischar(name)
    obj = i_create_array([1,1]);
    obj = assign(obj,name,type,assumedir);
elseif iscell(name)
    obj = i_create_array(size(name));
    for i=1:length(obj)
        obj(i) = assign(obj(i),name{i},type,assumedir);
    end
elseif isnumeric(name)
    s = name;
    if length(s)==1
        s = [s 1];
    elseif isempty(s)
        s = [0 1];
    end
    obj = i_create_array(s);
else
    error('mwood:tools:error','Unrecognised parameter');
end


%%%%%%%%%%%%%%%%
function obj = i_create_array(s)

st = struct('absname','',...
    'isdir',0,...
    'command','',...
    'dirpath','',...
    'extension','');
st = repmat(st,s);
obj = class(st,'mtfilename');
