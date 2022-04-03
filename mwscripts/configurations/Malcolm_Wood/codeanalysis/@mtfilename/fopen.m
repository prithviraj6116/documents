function f = fopen(obj,mode,error_on_failure)
%MTFILENAME/FOPEN Opens a file for reading or writing
%
%  f = fopen(obj) % open for reading.  return -1 on failure.
%  f = fopen(obj,mode) % open in specified mode.  return -1 on failure.
%  f = fopen(obj,mode,error_on_failure) % open in specified mode.
%                                       % Throw error on failure.
% See built-in fopen for allowed modes.

if length(obj)==1
    if isempty(obj.absname)
        % Presumably a missing command
        error('mwood:tools:error','Not a valid file name');
    end
    f = fopen(obj.absname,mode);
elseif numel(obj)==0
    error('mwood:tools:FileOpenError','Can''t open file for zero-length object');
else
    error('mwood:tools:FileOpenError','Can only open one file at a time');
end

if f==-1 && nargin>2 && error_on_failure
    if ~exist('mode','var') || isempty(mode) || mode(1)=='r'
        error('mwood:tools:FileOpenError','Failed to open file for reading: %s',obj.absname);      
    else
        error('mwood:tools:FileOpenError','Failed to open file for writing: %s',obj.absname);
    end
end


