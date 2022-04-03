function tempfile = viewslx(bdname,partname)
% VIEWSLX - Extracts a part from an SLX file an opens in the MATLAB Editor
%
% The "part" is extracted to a temporary file and opened in the MATLAB
% Editor.  Changes which are made to this file WILL NOT AFFECT THE
% ORIGINAL.  To make changes to the original file, use unpackslx and
% packslx.
%
% tempfile = viewslx(modelname); % blockdiagram.xml
% tempfile = viewslx(modelname,partname);
%
% e.g. 
%   viewslx sf_car
%   viewslx vdp /metadata/coreProperties.xml
%
% See also: unpackslx, packslx, clearslx

f = which(bdname);
if isempty(f)
    f = dependencies.absolute_filename(bdname);
end
if ~exist(f,'file')
    error('mwood:viewslx:filenotfound','File not found: %s',f);
end
if nargin<2 || isempty(partname)
    partname = '/simulink/blockdiagram.xml';
end

tf = [tempname '.xml'];
p = Simulink.loadsave.SLXPackageReader(f);
p.readPartToFile(partname,tf);

fprintf('Extracted "%s" from "%s"\n to "%s"\n',partname,f,tf);
edit(tf);
delete(tf);