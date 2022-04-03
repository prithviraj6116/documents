function clearslx
% CLEARSLX - Deletes a temporary folder created by unpackslx
%
% clearslx; % deletes current folder and restores pwd
%
% The intended workflow is:
%
%   unpackslx(modelname);
%   % Examine unzipped files
%   clearslx; % restore original state
%
% See also: packslx, unpackslx

if ~strncmp(tempdir,pwd,numel(tempdir))
    error('mwood:clearslx:invalidfolder','Not a valid temporary folder');
end
thisdir = pwd;
prevdir = evalin('base','slx_prevdir');
cd(prevdir);
rmdir(thisdir,'s');
evalin('base','clear slx_prevdir slx_filename');
