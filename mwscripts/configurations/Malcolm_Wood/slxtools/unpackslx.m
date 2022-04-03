function unpackslx(bdname)
% UNPACKSLX - Unpacks an SLX file into a new temporary folder
%
% unpackslx(modelname);
%
% A new folder is created and assigned as the current directory and
% the SLX file is unzipped into it for the purpose of viewing and/or
% editing its contents. Base workspace variables are created so that
% packslx can be used to commit any changes to the SLX file, or clearslx
% can be used to discard them.
%
% See also: packslx, clearslx

f = which(bdname);
if isempty(f)
    f = dependencies.absolute_filename(bdname);
end
if ~exist(f,'file')
    error('mwood:unpackslx:filenotfound','File not found: %s',f);
end
td = tempname;
mkdir(td);
prevdir = cd(td);
assignin('base','slx_prevdir',prevdir);
assignin('base','slx_filename',f);
unzip(f);
fprintf('Unpacked "%s"\n to "%s"\n',f,td)

xmlcmd = 'matlab:edit ./simulink/blockdiagram.xml';
cpcmd = 'matlab:edit ./metadata/coreProperties.xml';
mwcpcmd = 'matlab:edit ./metadata/mwcoreProperties.xml';
xmlhl = sprintf('<a href="%s">blockdiagram.xml</a>',xmlcmd);
cphl = sprintf('<a href="%s">coreProperties.xml</a>',cpcmd);
mwcphl = sprintf('<a href="%s">mwcoreProperties.xml</a>',mwcpcmd);
fprintf('Shortcuts to open: %s, %s, %s\n',xmlhl, cphl, mwcphl);

clearhl = '<a href="matlab:clearslx">clearslx</a>';
packhl = '<a href="matlab:packslx">packslx</a>';
fprintf('Shortcuts to: %s, %s\n', clearhl, packhl)
