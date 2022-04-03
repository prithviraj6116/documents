function compname = component_info(filename)

[status,out] = system(['mw component_info file info ' filename]);
if status~=0
    error('mwood:tools:component_info','%s',out);
end
disp(out);

t = strsplit(out,newline);
m = regexp(t,'Owned by: (?<c>.*)','names');
m = m{~cellfun(@isempty,m)};
compname = strtrim(m.c);

end