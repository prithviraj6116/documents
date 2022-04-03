function mods = read_module_list(makefile)

if nargin<1 || isempty(makefile)
    makefile = 'p4_cndefault.sbsmartbuild.mk';
end

t = mt_readtextfile(makefile);
m = regexp(t,'^# CppModDirs$');
ind = find(~cellfun('isempty',m));
if isempty(ind)
    error('mwood:tools:CppModDirs','Couldn''t find module list marker');
end

mods = {};
ind = ind(1) + 1;
while ind < numel(t)
    s = t{ind};
    if ~isempty(regexp(s,'^# EndCppModDirs$','once'))
        mods = mods(:);
        mods = slfullfile('matlab',mods);
        return;
    end
    s(1) = []; % strip leading '#'
    mods{end+1} = strtrim(s); %#ok<AGROW>
    ind = ind + 1;
end

end