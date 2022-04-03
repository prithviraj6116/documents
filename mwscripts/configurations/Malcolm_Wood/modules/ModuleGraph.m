classdef ModuleGraph < handle
% Class for analysing module dependencies, based on an sbsmartbuild
% makefile.
% 
% g = ModuleGraph('sb_mods.sbsmartbuild.mk')   
% g.immediateDownstream('sl_loadsave')
%
    properties
        graph;
        modules;
        aliases;
    end
    
    methods (Access = public)
        function obj = ModuleGraph(makefile)
            [obj.graph,obj.modules,obj.aliases] = get_module_graph(makefile);
        end
        
        function mods = allUpstream(obj,m)
            mods = dfsearch(obj.graph,m);
        end
        
        function mods = allDownstream(obj,m)
            mods = dfsearch(flipedge(obj.graph),m);
        end
        
        function mods = immediateUpstream(obj,m)
            e = obj.graph.Edges.EndNodes;
            match = strcmp(e(:,1),m);
            mods = e(match,2);
        end
        
        function mods = immediateDownstream(obj,m)
            e = obj.graph.Edges.EndNodes;
            match = strcmp(e(:,2),m);
            mods = e(match,1);
        end
        
        function mod = getModule(obj,alias)
            [found,ind] = slcellmember(alias,obj.aliases);
            if any(~found)
                if ~iscell(alias)
                    alias = {alias};
                end
                error('mwood:tools:module_alias','Alias not found: %s\n',alias{~found});
            end
            mod = obj.modules(ind);
            if ischar(mod)
                mod = mod{1};
            else
                mod = mod(:);
            end
        end
        
        function alias = getAlias(obj,mod)
            [found,ind] = slcellmember(mod,obj.modules);
            if any(~found)
                if ~iscell(mod)
                    mod = {mod};
                end
                error('mwood:tools:module_alias','Module not found: %s\n',mod{~found});
            end
            alias = obj.aliases(ind);
            if ischar(mod)
                alias = alias{1};
            else
                alias = alias(:);
            end
        end
        
    end
    
    
end