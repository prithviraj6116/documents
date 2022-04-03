function comparebdxml(slxfile1,slxfile2,partname)

if nargin<3 || isempty(partname)
    partname = '/simulink/blockdiagram.xml';
end

f1 = which(slxfile1);
if isempty(f1)
    f1 = dependencies.absolute_filename(slxfile1);
end
if ~exist(f1,'file')
    error('mwood:unpackslx:filenotfound','File not found: %s',slxfile1);
end
slxfile1 = f1;

f2 = which(slxfile2);
if isempty(f2)
    f2 = dependencies.absolute_filename(slxfile2);
end
if ~exist(f2,'file')
    error('mwood:unpackslx:filenotfound','File not found: %s',slxfile2);
end
slxfile2 = f2;

[~,s1] = fileparts(slxfile1);
tf1 = [tempname '_' s1 '.xml'];
p = Simulink.loadsave.SLXPackageReader(slxfile1);
p.readPartToFile(partname,tf1);

[~,s2] = fileparts(slxfile2);
tf2 = [tempname '_' s2 '.xml'];
p = Simulink.loadsave.SLXPackageReader(slxfile2);
p.readPartToFile(partname,tf2);

visdiff(tf1,tf2,'text');

end
