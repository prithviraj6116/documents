function cdeditordoc

f = editordoc;
d = fileparts(f);
startdir = cd(d);
fprintf('Set pwd to <a href="matlab:cd %s">%s</a>\n',startdir,startdir);
