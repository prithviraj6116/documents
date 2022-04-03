function filedir(f)
% Changes to the folder containing the specified file

r = which(f);
if isempty(r)
    error('mwood:tools:NotFound','File not found: %s',f);
end
d = fileparts(r);
olddir = cd(d);
fprintf('pwd = <a href="matlab: cd %s">%s</a>\n',d,d);
fprintf('prevdir = <a href="matlab: cd %s">%s</a>\n',olddir,olddir);
