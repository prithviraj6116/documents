% Class for analyzing components and their dependencies
classdef ComponentAnalysis_Old < handle
    properties
        components = {};
        componentNames;
        root = mt_fullfile(sbroot,'matlab');
    end
    methods
        function loadAllComponents(obj)
        % Load and analyze all component XML files.
            tic;
            if isempty(obj.componentNames)
                obj.allComponentNames;
            end
            obj.components = cell(size(obj.componentNames));
            for i=1:numel(obj.componentNames)
                obj.loadComponent(obj.componentNames{i},i);
            end
            t = toc;
            fprintf('Read %d components in %f seconds\n',numel(obj.components),t);
        end
        
        function printComponentTree(obj,componentname)
        % Prints the entire component hierarchy upstream from the specified
        % component.
            compinfo = obj.findComponent(componentname);
            obj.printComponentSubtree(compinfo,'',{});
        end

        function compnames = upstreamToPrincipal(obj,componentname,already_found)
            if nargin<3
                already_found = {};
            end
            if iscell(componentname)
                compnames = {};
                for i=1:numel(componentname)
                    if ~ismember(componentname{i},compnames)
                        a = obj.upstreamToPrincipal(componentname{i},already_found);
                        compnames = unique([compnames ; a]);
                    end
                end
                return;
            end
            
            c = obj.findComponent(componentname);
            compnames = c.dependsOn;
            compdeps = cell(size(compnames));
            for i=1:numel(compnames)
                thiscomp = compnames{i};
                if ~mt_cellmember(thiscomp,already_found)
                    c = obj.findComponent(thiscomp);
                    if ~c.isPrincipal && ~c.isBuildTool
                        found = obj.upstreamToPrincipal(thiscomp,already_found);
                        compdeps{i} = [{thiscomp} ; found];
                        already_found = [ already_found ; compdeps{i} ]; %#ok<AGROW>
                    else
                        compdeps{i} = {thiscomp};
                        already_found = [ already_found ; {thiscomp} ]; %#ok<AGROW>
                    end
                end
            end
            compnames = unique(vertcat(compdeps{:}));
        end
        
        function compnames = allUpstreamComponents(obj,componentname)
        % Returns all the components which are upstream of the named one.
            if iscell(componentname)
                compnames = {};
                for i=1:numel(componentname)
                    if ~mt_cellmember(componentname{i},compnames)
                        a = obj.allUpstreamComponents(componentname{i});
                        compnames = unique([compnames ; a]);
                    end
                end
                return;
            end
            c = obj.findComponent(componentname);
            if iscell(c.allUpstreamComponents)
                compnames = c.allUpstreamComponents;
                return;
            end
            compnames = c.dependsOn;
            %compdeps = cell(size(compnames));
            tmp = compnames;
            for i=1:numel(tmp)
                try
                    %compdeps{i} = 
                    compdeps = obj.allUpstreamComponents(tmp{i});
                    compnames = unique(vertcat(compnames,compdeps));
                catch E
                    disp(E.message);
                end
            end
            %compnames = unique(vertcat(compnames,compdeps{:}));
            c.allUpstreamComponents = compnames;
        end
        
        function compnames = upstreamComponentsFrom(obj,component_from,component_to)
        % Returns all the components which are upstream from component_from,
        % excluding those which are downstream from component_to.
        % For example: to identify components installed by simulink:
        %  obj.upstreamComponentsFrom('simulink','matlab');
            c_all = obj.allUpstreamComponents(component_from);
            if ~mt_cellmember(component_to,c_all)
                error('mwood:Comp:Deps','Component %s does not depend on component %s',...
                     component_from,component_to);
            end
            c_exclude = obj.allUpstreamComponents(component_to);
            compnames = setdiff(c_all,c_exclude);
            compnames = setdiff(compnames,{component_to});
        end
        
        function compnames = immediateDownstreamComponents(obj,componentname,subset)
        % Returns the components that depend directly on the specified one.
            if nargin<3
                subset = obj.allComponentNames;
            end
            d = cell(size(obj.components));
            for i=1:numel(obj.components)
                c = obj.getComponent(i);
                if mt_cellmember(c.componentName,subset) && mt_cellmember(componentname,c.dependsOn)
                    d{i} = c.componentName;
                end
            end
            compnames = d(~cellfun(@isempty,d));
        end
        
        function compnames = immediateUpstreamComponents(obj,componentname,subset)
            % Returns the components on which the specified one depends
            c = obj.findComponent(componentname);
            compnames = c.dependsOn;
            if nargin>2
                compnames = intersect(compnames,subset);
            end
        end
        
        function c = findComponent(obj,componentname)
        % Returns the details of the specified component
            if ~ischar(componentname)
                error('mwood:Comp:Deps','Component name must be string');
            end
            [a,b] = mt_cellmember(componentname,obj.allComponentNames);
            if a
                c = obj.getComponent(b);
                return;
            end
            error('mwood:Comp:Deps','Component not found: %s',componentname);
        end
        
        function c = dependsOn(obj,componentname)
            a = obj.findComponent(componentname);
            c = a.dependsOn;
        end
        
        function n = matchingComponentNames(obj,pattern)
        % Returns a unique list of components whose names match the 
        % specified regular expression(s).
            if iscell(pattern)
                matches = cell(size(pattern));
                for i=1:numel(pattern)
                    matches{i} = obj.matchingComponentNames(pattern{i});
                end
                matches = vertcat(matches{:});
                n = unique(matches);
                return;
            end
            m = regexp(obj.allComponentNames,pattern);
            m = ~cellfun(@isempty,m);
            n = obj.componentNames(m);
        end
        
        function printDependencySubtree(obj,componentname,target,stop_at)
        % Prints the branches of the dependency tree by which
        % componentname depends on target.
            if nargin<4
                stop_at = {};
            end
            [~,b] = obj.dependencySubtree(componentname,target,stop_at);
            for i=1:numel(b)
                branch = b{i};
                fprintf('%s\n',componentname);
                indent = '  ';
                for k=1:numel(branch)
                    fprintf('%s%s\n',indent,branch{k});
                    indent = [indent '  ']; %#ok<AGROW>
                end
                fprintf('\n');
            end
        end
        
        function [comps,branches,stop_at] = dependencySubtree(obj,componentname,target,stop_at)
        % Returns the branches of the dependency tree by which
        % componentname depends on target.  The first output is the
        % names of components included directly by this one which implcitly
        % depend on the target component.  The second is the paths by which
        % these implicit dependencies occur.  Branches stop when they:
        % * Reach a principal component that depends on the target.
        % * Or reach a component from which all routes to the target have
        %   already been printed in previous branches.
            if strcmp(componentname,target)
                comps = {componentname};
                branches = {{componentname}};
                return;
            end
            
            if nargin<4
                stop_at = {};
            end
        
            c = obj.findComponent(componentname);
            d = false(size(c.dependsOn));

            branches = {};
            
            for i=1:numel(c.dependsOn)
                sc = c.dependsOn{i};
                if strcmp(sc,target)
                    branches = [branches ; {{sc}}]; %#ok<AGROW>
                    d(i) = true;
                elseif mt_cellmember(sc,stop_at)
                    % There's an earlier branch that includes this
                    % component so we can stop this branch here.
                    branches = [branches ; {{sc}}]; %#ok<AGROW>
                    d(i) = true;                    
                else
                    cr = obj.findComponent(sc);
                    if ~iscell(cr.allUpstreamComponents)
                        obj.allUpstreamComponents(sc);
                    end
                    if mt_cellmember(target,cr.allUpstreamComponents)
                        if cr.isPrincipal || cr.isBuildTool
                            % A principal component
                            branches = [branches ; {{sc}}]; %#ok<AGROW>
                        else
                            % Try upstream components
                            [~,b,stop_at] = obj.dependencySubtree(c.dependsOn{i},target,stop_at);
                            if ~isempty(b)
                                for k=1:numel(b)
                                    b{k} = [sc ; b{k}];
                                end
                                branches = [branches ; b]; %#ok<AGROW>
                            end
                        end
                        d(i) = true;
                        stop_at = [stop_at(:) ; {sc}];
                    end
                end
            end
            comps = c.dependsOn(d);
        end
        
        function [d,implicit] = minimalDependencies(c,name)
        % Identifies the minimal set of upstream components on which this one
        % directly depends,
            comp = c.findComponent(name);
            [d,implicit] = c.minimalSet(comp.dependsOn);
        end
        
        function editConfig(c,name)
            edit(mt_fullfile(c.root,'config','components',[name '.xml']));
        end
        
        function [d,implicit] = minimalSet(c,comps)
        % Identifies the minimal set of upstream components on which this one
        % directly depends,
            implicit = false(numel(comps),1);
            for i=1:numel(comps)
                if ~implicit(i)
                    upstream = c.allUpstreamComponents(comps{i});
                    found = mt_cellmember(comps,upstream);
                    implicit = implicit | found;
                end
            end
            d = comps(~implicit);
            implicit = comps(implicit);
        end
        
        function writeCache(obj,filename)
            comps = obj.components; %#ok<NASGU>
            names = obj.componentNames; %#ok<NASGU>
            root = obj.root; %#ok<NASGU,PROP>
            timestamp = datestr(now); %#ok<NASGU>
            if nargin<2
                filename = mt_fullfile(pwd,'component_cache.mat');
            end
            save(filename,'comps','names','root','timestamp');
        end
        
        function downstream = downstreamComponentsTo(c,component_from,component_to)
        % Identifies components downstream of component_from and
        % upstream of component_to.  For example, if modifying
        % shared_simulink_block and running simulink_core_tests, the
        % components which need to be rebuild are:
        %  obj.downstreamDependenciesFrom('shared_simulink_block','simulink_core_tests');

            % Everything upstream of component_to and not upstream of
            % component_from.
            if nargin>2 && ~isempty(component_to)
                subset = c.upstreamComponentsFrom(component_to,component_from);
            else
                subset = c.allComponentNames;
            end
            if ~isempty(subset)
                % Now exclude those which are not downstream of component_from.
                downstream = c.downstreamDependencies(component_from,subset);
                % Include the "to" and "from" components.
                downstream{end+1} = component_from;
                downstream{end+1} = component_to;
                downstream = sort(downstream);
            else
                downstream = {};
            end
        end

        function downstream = downstreamDependencies(c,component,subset)
        % Identifies components downstream of the specified one from the
        % (optional) supplied subset.
            if nargin<3 || isempty(subset)
                subset = c.allComponentNames;
            end
            % First remove all upstream components
            upstream = c.allUpstreamComponents(component);
            subset = setdiff(subset,upstream);
            isdownstream = false(size(subset));
            for i=1:numel(subset)
                upstream = c.allUpstreamComponents(subset{i});
                isdownstream(i) = mt_cellmember(component,upstream);
            end
            downstream = subset(isdownstream);
        end
        
        function compnames = allDownstreamComponents(c,componentname)
        % Identifies components downstream of the specified one.
            if iscell(componentname)
                compnames = {};
                for i=1:numel(componentname)
                    if ~mt_cellmember(componentname{i},compnames)
                        a = c.downstreamDependencies(componentname{i});
                        compnames = unique([compnames ; a]);
                    end
                end
                return;
            end    
            compnames = c.downstreamDependencies(componentname);
        end

        function c = allComponentNames(obj)
            if ~isempty(obj.componentNames)
                c = obj.componentNames;
                return;
            end
            compfolder = mt_fullfile(obj.root,'config','components');
            tic;
            c = mt_filesearch(compfolder,true,'.xml');
            pattern = ['.*config\' filesep 'components\' filesep '(?<compname>.*).xml'];
            n = regexp(getabsx(c),pattern,'names');
            e = find(cellfun(@isempty,n));
            for i=1:numel(e)
                warning('mwood:comps:nocomp','Can''t identify component name in: %s',getabs(c(i)));
            end
            n = [n{:}];
            c = {n.compname}';
            c = strrep(c,'\','/');
            fprintf('Found %d components in %f seconds\n',numel(c),toc);
            obj.componentNames = c;
            obj.components = cell(size(c));
        end
        
        function depGraph = getComponentGraph(c,names)
            numNodes = length(c.components);
            numEdges = sum(cellfun(@(x) length(x.dependsOn), c.components));
            srcs = cell(1, numEdges);
            dsts = cell(1, numEdges);
            currEdge = 1;
            for dstID = 1:numNodes
                dstComp = c.getComponent(dstID);
                dstName = dstComp.componentName;

                srcComponents = dstComp.dependsOn();
                for srcIdx = 1:length(srcComponents)
                    srcName = srcComponents{srcIdx};

                    srcs{currEdge} = srcName;
                    dsts{currEdge} = dstName;
                    currEdge = currEdge + 1;
                end
            end
            depGraph = digraph(srcs, dsts, [], c.allComponentNames);
            
            if nargin>1 && ~isempty(names)
                depGraph = subgraph(depGraph,names);
            end
        end

        function h = plotComponentGraph(c,names)
            g = getComponentGraph(c,names);
            h = plot(g,'NodeLabelMode','auto','Layout','layered');
        end
        
        function reloadComponent(obj,compname)
            ind = find(strcmp(compname,obj.componentNames));
            if isempty(ind)
                error('mwood:tools:ComponentNotFound','Unknown component: %s',compname);
            end
            c = componentReader(compname);
            c.root = obj.root;
            c.loadComponent;
            obj.components{ind} = c;
            % Reset all cached lists of upstream components.
            for i=1:numel(obj.components)
                obj.components{i}.allUpstreamComponents = [];
            end
        end
        
    end
        
    methods (Access=private)
        
        function loadComponent(obj,compname,ind)
            c = componentReader(compname);
            c.root = obj.root;
            c.loadComponent;
            obj.components{ind} = c;
        end
        
        function c = getComponent(obj,ind)
            if isempty(obj.components{ind})
                n = obj.allComponentNames;
                obj.loadComponent(n{ind},ind);
            end
            c = obj.components{ind};
        end
        
        function printed = printComponentSubtree(obj,compinfo,indent,already_printed)
            fprintf('%s%s\n',indent,compinfo.componentName);
            already_printed = [ already_printed ; {compinfo.componentName} ];
            for i=1:numel(compinfo.dependsOn)
                c = obj.findComponent(compinfo.dependsOn{i});
                if ~mt_cellmember(c.componentName,already_printed)
                    newly_printed= obj.printComponentSubtree(c,[indent '   '],already_printed);
                    already_printed = [ already_printed ; newly_printed(:) ]; %#ok<AGROW>
                %else
                    %fprintf('%s   %s (again)\n',indent,c.componentname);
                end
            end
            printed = unique(already_printed);
        end
        
    end
    methods (Static)
        function obj = loadFromCache(filename)
            if nargin<1
                filename = mt_fullfile(pwd,'component_cache.mat');
            end
            comps = load(filename);
            obj = ComponentAnalysis_Old;
            obj.components = comps.comps;
            obj.componentNames = comps.names;
            obj.root = comps.root;
            fprintf('Cache created %s for %s\n',comps.timestamp,comps.root);
        end
    end
end

