function remove_module_dependency(mod,module_to_remove)
% Removes an entry from a MODULE_DEPENDENCIES file
%
%  remove_module_dependency(mod,module_to_remove)
%
% "mod" is the module containing the MODULE_DEPENDENCIES file to edit,
%    relative to matlabroot.  (e.g. src/sl_graphical_classes)
% "module_to_remove" is in the format used in MODULE_DEPENDENCIES itself
%    (e.g. libmwsimulink).

mdfile = slfullfile(sbroot,'matlab',mod,'MODULE_DEPENDENCIES');
if isempty(Simulink.loadsave.resolveFile(mdfile))
    error('mwood:tools:remove_module_dependency','MODULE_DEPENDENCIES file not found in %s',mod);
end

t = mt_readtextfile(mdfile);
n = find(~cellfun('isempty',regexp(t,['=?' module_to_remove])));
if isempty(n)
    fprintf('Dependency not found in %s: %s\n',mod, module_to_remove);
    return;
end

for i=numel(n):-1:1
    ind = n(i);
    t(ind) = [];
    if ~isempty(regexp(t{ind-1},'^# .* exports:','once'))
        t(ind-1) = [];
    elseif ~isempty(regexp(t{ind-1},'^# Use of MODULE','once'))
        t(ind-1) = [];
    end
end

p4edit(mdfile);
mt_writetextfile(mdfile,t);