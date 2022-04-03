function p4edit(filename)

if iscell(filename)
    for i=1:numel(filename)
        p4edit(filename{i});
    end
    return;
end

res = Simulink.loadsave.resolveFile(filename);
if isempty(res)
    error('mwood:tools:p4edit','Not found: %s',filename);
end

[d,n,e] = fileparts(res);
startdir = cd(d);
restoredir = onCleanup(@() cd(startdir));
[~,output] = system(sprintf('p4 edit %s%s',n,e));
disp(strtrim(output));

end
