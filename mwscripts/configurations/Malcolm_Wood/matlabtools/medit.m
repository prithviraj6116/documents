function medit(filename)

filename = strrep(filename,'\','/');

f = i_resolve(filename);
if ~isempty(f)
    fprintf('%s\n',f);
    edit(f);
else
    error('mwood:tools:FileNotFound','File not found: %s',filename);
end

end

function f = i_resolve(filename)

[d,n,ext] = slfileparts(filename);
if isempty(ext)
    filename = slfullfile(d,[n '.m']);
end

f = Simulink.loadsave.resolveFile(filename);
if ~isempty(f)
    return;
end

f = Simulink.loadsave.resolveFile(slfullfile(matlabroot,filename));
if ~isempty(f)
    return;
end

f = Simulink.loadsave.resolveFile(slfullfile(slfileparts(matlabroot),filename));
if ~isempty(f)
    return;
end

end