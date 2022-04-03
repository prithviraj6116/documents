function cdContainingFolder(func)

f = which('-all',func);
if isempty(f)
    error('mwood:tools:cd','Function not found: %s\n',func);
end
dirname = fileparts(f{1});
startdir = pwd;
cd(dirname);
fprintf('Initial cwd: <a href="matlab:cd %s">%s</a>\n',startdir,startdir);
fprintf('New cwd: <a href="matlab:cd %s">%s</a>\n',dirname,dirname);

