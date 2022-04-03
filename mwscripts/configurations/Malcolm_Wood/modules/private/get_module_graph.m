function [g,mods,aliases] = get_module_graph(makefile)
% [graph,mods,aliases] = get_module_graph(makefile)
%
% Could alternatively use the module_data.xml files in "derived"

t = mt_readtextfile(makefile);

% Trim length "WARNINGS" section from the makefile
m = regexp(t,'WARNINGS');
ind = find(~cellfun('isempty',m));
t(ind(end):end) = [];

mods = i_get_modules(t);

deps = {};
aliases = {};
for i=1:numel(mods)
    [deps{i},aliases{i}] = i_get_deps(t,mods{i}); %#ok<AGROW>
end

g = digraph;
g = g.addnode(aliases);
for i=1:numel(mods)
    [~,ind] = slcellmember(deps{i},aliases);
    ind = unique(ind);
    ind(ind==0) = []; % e.g. $(if SB_IS_ARCH...)
    g = g.addedge(i,ind);
end

end

function mods = i_get_modules(t)

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
        %mods = slfullfile('matlab',mods);
        return;
    end
    s(1) = []; % strip leading '#'
    mods{end+1} = strtrim(s); %#ok<AGROW>
    ind = ind + 1;
end

end

function [deps,alias] = i_get_deps(t,mod)
m = regexp(t,['^#\s*' strrep(mod,'/','\/') '\/[^\/]* from']);
ind = find(~cellfun('isempty',m));
ind = ind(1);
% Find next line with .PHONY
p = ind+1;
while true
    if contains(t{p},'PHONY')
        break;
    end
    p = p + 1;
end
p = p + 1; % step only target line
alias = t{p};
x = find(alias==':');
alias(x:end) = []; % strip colon and everything after it

deps = {};
p = p + 1; % step to first dependency
while t{p}(1)==char(9)
    depmod = t{p};
    if depmod(end)=='\'
        depmod(end) = []; % strip backslash
    end
    depmod = strtrim(depmod);
    deps{end+1} = depmod; %#ok<AGROW>
    p = p + 1;
end
deps = deps(:);

end
