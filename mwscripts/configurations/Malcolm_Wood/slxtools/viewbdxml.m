function tf = viewbdxml(bdname)

f = which(bdname);
if isempty(f)
    f = dependencies.absolute_filename(bdname);
end
if ~exist(f,'file')
    error('mwood:unpackslx:filenotfound','File not found: %s',f);
end
if exist('Simulink.loadsave.SLXPackageReader')
    tf = [tempname '.xml'];
    p = Simulink.loadsave.SLXPackageReader(f);
    p.readPartToFile('/simulink/blockdiagram.xml',tf);
else
    % R2014a and earlier
    tf = sls_extractpart(f,'/simulink/blockdiagram.xml',tempdir);
end
edit(tf);
delete(tf);
end
