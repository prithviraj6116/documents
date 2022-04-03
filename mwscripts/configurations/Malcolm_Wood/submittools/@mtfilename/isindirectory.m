function b = isindirectory(obj,directory)
%MTFILENAME/ISINDIRECTORY Determines whether this item is in the specified directory
%
% b = isindirectory(obj,directory)
%
% "directory" must identify a single directory
% "obj" can be any number of ntfilename instances.  "b" is a logical
% array of the same size.


% Copyright 2006 The MathWorks, Inc.
b = false(size(obj));
directory = mtfilename(directory);

if ~isdir(directory)
    error([ getabs(directory) ' is not a directory']);
end

% Append a separator to "d" so that, for example, we don't
% consider C:\TempX\file.txt to be inside C:\Temp
d = [ lower(getabs(directory)) filesep ];

for i=1:numel(obj)
    % Append a separator to the filename, just incase it
    % is exactly the same as the directory name.
    f = [ lower(getabs(obj(i))) filesep ];
    b(i) = strncmp(f,d,numel(d));
end


