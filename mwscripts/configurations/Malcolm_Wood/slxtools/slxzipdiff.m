function slxzipdiff(f1,f2)

r1 = Simulink.loadsave.resolveFile(f1,'slx');
if isempty(r1)
    error('File not found: %s',f1);
end
r2 = Simulink.loadsave.resolveFile(f2,'slx');
if isempty(r2)
    error('File not found: %s',f2);
end
[~,n1] = slfileparts(r1);
[~,n2] = slfileparts(r2);
z1 = slfullfile(tempdir,[n1 '_temp.zip']);
z2 = slfullfile(tempdir,[n2 '_temp.zip']);
copyfile(r1,z1);
copyfile(r2,z2);
visdiff(z1,z2);

end