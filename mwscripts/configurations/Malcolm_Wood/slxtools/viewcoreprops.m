function tf = viewcoreprops(slxfile)

tf = [tempname '.xml'];
p = Simulink.loadsave.SLXPackageReader(slxfile);
p.readPartToFile('/metadata/coreproperties.xml',tf);

edit(tf);
delete(tf);
