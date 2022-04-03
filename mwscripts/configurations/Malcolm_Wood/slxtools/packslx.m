function packslx(filename)
% PACKSLX - Rewrites an SLX file unpacked by unpackslx
%
% packslx; % rewrites file last unpacked by unpackslx
% packslx(filename); % packs the temporary folder into the specified file
%
% The contents of temporary folder created by unpackslx are written to
% the SLX file.  The temporary folder is deleted and MATLAB's original 
% current folder restored.
%
% The intended workflow is:
%   unpackslx(modelname);
%   % Make some changes to the files in the temporary folder
%   packslx; % apply those changes to the original SLX file
%
% See also: unpackslx, clearslx

if ~strncmp(tempdir,pwd,numel(tempdir))
    error('mwood:packslx:invalidfolder','Not a valid temporary folder');
end
prevdir = evalin('base','slx_prevdir');
if nargin<1
    filename = evalin('base','slx_filename');
end

f = dir(pwd);
f = f(3:end); % exclude "." and "..".
zip('tmp.zip',{f.name});
try
    copyfile('tmp.zip',filename);
catch E %#ok<NASGU>
    copyfile('tmp.zip',[filename '_tmp']);
    fprintf('Couldn''t write file.  Copied to %s instead\n',[filename '_tmp']);
end
tmpdir = cd(prevdir);
rmdir(tmpdir,'s')