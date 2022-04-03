function trim_module_dependencies(g,module_to_remove)
% Identifies modules which unnecessarily depend on the specified one, and
% updates their MODULE_DEPENDENCIES files to remove the dependency.
%
%  trim_module_dependencies(g,module_to_remove)
%
% "g" is an instance of ModuleGraph
% "module_to_remove" is the "alias" of the module as found in "g.aliases"
%    (e.g. libmwsimulink or sl_loadsave).

aliases = g.immediateDownstream(module_to_remove);

for i=1:numel(aliases)
    mod = g.getModule(aliases{i});
    if strncmp(module_to_remove,'libmw',5)
        module_to_remove = module_to_remove(6:end);
    end
    i_trim(mod{1},module_to_remove);
end

end


function i_trim(mod,to_remove)
    restore_dir = mt_cd(slfullfile(sbroot,'matlab',mod));
    [f,t] = count_inclusions(['\/' to_remove '\/']);
    if f==0 && t~=0
        try
            remove_module_dependency(mod,to_remove);
        catch E
            ple(E);
        end
    end

end

