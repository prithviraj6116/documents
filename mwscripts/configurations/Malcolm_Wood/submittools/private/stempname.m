function n = stempname(appname,prefix)
%STEMPNAME Creates an application-specific temporary file name
%
% name = stempname(appname)
% name = stempname(appname,prefix)
%
% The name has no extension and refers to a location inside
% the applications temporary directory, which is inside
% MATLAB's temporary directory.
% The directory is created on the first call to this function.
% The name is not guaranteed to be unique, but is likely to be.

if nargin<1
    appname = 'MT';
    if nargin<2
        prefix = 'tp';
    end
end

[d,n] = fileparts(tempname);
d = fullfile(d,appname);

if exist(d,'dir')~=7
    [a,b] = dos(['mkdir ' d]);
    if a
        error(['Failed to created temporary directory: ' b]);
    end
end

% n always start with "tp".  Remove it
n = n(3:end);

n = fullfile(d,[prefix n]);


