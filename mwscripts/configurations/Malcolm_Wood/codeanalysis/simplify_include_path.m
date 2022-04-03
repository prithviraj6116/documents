function r = simplify_include_path(f)
% r= simplify_include_path(f)
%
% Given a path like:
%  '../../derived/glnxa64/src/include/slcg/../../../../../src/slcg/export/include/slcg/SLCGFileRepository.hpp'
% simplifies it to the string that would need to be written in a #include
% directive, in this case:
%  slcg/SLCGFileRepository.hpp
%

if iscell(f)
    r = f;
    for i=1:numel(r)
        r{i} = simplify_include_path(f{i});
    end
    return;
end

if strncmp(f,'./',2)
    % in this module
    r = f;
    return;
end

m = regexp(f,'\/derived\/glnxa64\/src\/include\/(?<mod>[^\/]*)\/(?<rest>.*)','names');
if ~isempty(m)
    mod = m.mod;
    r = m.rest;
    m = regexp(r,'\/export\/include\/(?<rel>.*)','names');
    if ~isempty(m)
        r = m.rel;
        m = strtok(r,'/');
        if ~strcmp(m,mod)
            r = slfullfile(mod,r);
        end
    else
        r = slfullfile(mod,r);
    end
    return;
end

m = regexp(f,'\/boost\/include\/(?<rel>.*)','names');
if ~isempty(m)
    r = ['<' m.rel '>'];
    return;
end

r = Simulink.loadsave.resolveFile(f);

[d,n,e] = slfileparts(r);
if strcmp(d,'/usr/include')
    r = ['<' n e '>'];
    return;
end

cppdir = '/usr/include/c++/4.9/';
if strncmp(d,cppdir,numel(cppdir))
    r = ['<' r(numel(cppdir)+1:end) '>'];
    return;
end

end