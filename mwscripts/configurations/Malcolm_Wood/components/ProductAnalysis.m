% Class for analyzing products and the components they contain
classdef ProductAnalysis < handle
    properties
        productKeys = {};
        products = {};
        root = fullfile(sbroot,'matlab');
    end
    methods
        function loadAllProducts(obj)
        % Load and analyze all product XML files.
            tic;
            if isempty(obj.productKeys)
                obj.allProductKeys;
            end
            obj.products = cell(size(obj.productKeys));
            for i=1:numel(obj.productKeys)
                try
                    obj.loadProduct(obj.productKeys{i},i);
                end
            end
            t = toc;
            fprintf('Read %d product definitions in %f seconds\n',numel(obj.products),t);
        end
        
        function printComponentTree(obj,componentname)
        % Prints the entire component hierarchy upstream from the specified
        % component.
            compinfo = obj.findComponent(componentname);
            obj.printComponentSubtree(compinfo,'',{});
        end
        
        function compnames = allUpstreamComponents(obj,c,prodkey)
        % Returns all the components which are required by the product.
            assert(isa(c,'ComponentAnalysis'));
            assert(isa(obj,'ProductAnalysis'));
            assert(isa(prodkey,'char') || iscellstr(prodkey));
            if iscell(prodkey)
                compnames = {};
                for i=1:numel(prodkey)
                    if ~ismember(prodkey{i},compnames)
                        a = obj.allUpstreamComponents(c,prodkey{i});
                        compnames = unique([compnames ; a]);
                    end
                end
                return;
            end
            p = obj.findProduct(prodkey);
            pdeps = p.getProductDependencies;
            cdeps = p.getComponentDependencies;
            compnames = cell(1,numel(pdeps) + numel(cdeps));
            for i=1:numel(pdeps)
                compnames{i} = obj.allUpstreamComponents(c,pdeps{i});
            end
            for i=1:numel(cdeps)
                compnames{i+numel(pdeps)} = c.allUpstreamComponents(cdeps{i});
            end
            compnames = vertcat(compnames{:},cdeps);
            compnames = unique(compnames);
        end
        
        function compnames = getProductComponents(obj,c,prodkey)
            % Returns the components which are required by the specified
            % but not by any of its upstream products.
            assert(isa(c,'ComponentAnalysis'),'ComponentAnalysis instance required');
            assert(isa(obj,'ProductAnalysis'),'ProductAnalysis instance required');
            assert(isa(prodkey,'char'));
            p = obj.findProduct(prodkey);
            rc = p.getComponentDependencies;
            compnames = c.upstreamToPrincipal(rc);
        end
        
        
        function compnames = upstreamComponentsFrom(obj,component_from,component_to)
        % Returns all the components which are upstream from component_from,
        % excluding those which are downstream from component_to.
        % For example: to identify components installed by simulink:
        %  obj.upstreamComponentsFrom('simulink','matlab');
            c_all = obj.allUpstreamComponents(component_from);
            if ~ismember(component_to,c_all)
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
                if ismember(c.componentName,subset) && ismember(componentname,c.dependsOn)
                    d{i} = c.componentName;
                end
            end
            compnames = d(~cellfun(@isempty,d));
        end
        
        function c = findProduct(obj,prodkey)
        % Returns the details of the specified product
            if ~ischar(prodkey)
                error('mwood:prod:Deps','Product key must be string');
            end
            [a,b] = ismember(prodkey,obj.allProductKeys);
            if a
                c = obj.getProduct(b);
                return;
            end
            error('mwood:prod:Deps','Product not found: %s',prodkey);
        end
        
        function c = dependsOn(obj,componentname)
            a = obj.findComponent(componentname);
            c = a.dependsOn;
        end
        
        function n = matchingProductNames(obj,pattern)
        % Returns a unique list of products whose keys match
        % the specified regular expression(s).
            if iscell(pattern)
                matches = cell(size(pattern));
                for i=1:numel(pattern)
                    matches{i} = obj.matchingProductNames(pattern{i});
                end
                matches = vertcat(matches{:});
                n = unique(matches);
                return;
            end
            m = regexp(obj.allProductKeys,pattern);
            m = ~cellfun(@isempty,m);
            n = obj.productKeys(m);
        end
        
        function p = productForPrincipalComponent(obj,c)
            if iscell(c)
                p = cell(size(c));
                for i=1:numel(c)
                    p{i} = obj.productForPrincipalComponent(c{i});
                end
                p = vertcat(p{:});
                n = unique(p);
                return;
            end
            p = [];
            for i=1:numel(obj.products)
                d = obj.products{i}.getComponentDependencies;
                if slcellmember(c,d)
                    if ~isempty(p)
                        p = [p ', '];
                    end
                    p = [p obj.products{i}.productKey];
                end
            end
        end
        
        function printDependencySubtree(obj,componentname,target)
        % Prints the branches of the dependency tree by which
        % componentname depends on target.
            [~,b] = obj.dependencySubtree(componentname,target);
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
        
        function [comps,branches] = dependencySubtree(obj,componentname,target)
        % Returns the branches of the dependency tree by which
        % componentname depends on target.  The first output is the
        % names of components included directly by this one which implcitly
        % depend on the target component.  The second is the paths by which
        % these implicit dependencies occur.
            if strcmp(componentname,target)
                comps = {componentname};
                branches = {{componentname}};
                return;
            end
        
            c = obj.findComponent(componentname);
            d = false(size(c.dependsOn));

            branches = {};
            
            for i=1:numel(c.dependsOn)
                sc = c.dependsOn{i};
                if strcmp(sc,target)
                    branches = [branches ; {{sc}}]; %#ok<AGROW>
                    d(i) = true;
                elseif ismember(target,obj.allUpstreamComponents(sc))
                    % Try upstream components
                    [~,b] = obj.dependencySubtree(c.dependsOn{i},target);
                    if ~isempty(b)
                        for k=1:numel(b)
                            b{k} = [sc ; b{k}];
                        end
                        branches = [branches ; b]; %#ok<AGROW>
                    end
                    d(i) = true;
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
            edit(fullfile(c.root,'config','products',[name '.xml']));
        end
        
        function [d,implicit] = minimalSet(c,comps)
        % Identifies the minimal set of upstream components on which this one
        % directly depends,
            implicit = false(numel(comps),1);
            for i=1:numel(comps)
                if ~implicit(i)
                    upstream = c.allUpstreamComponents(comps{i});
                    found = ismember(comps,upstream);
                    implicit = implicit | found;
                end
            end
            d = comps(~implicit);
            implicit = comps(implicit);
        end
        
        function writeCache(obj,filename)
            comps = obj.components; %#ok<NASGU>
            names = obj.productKeys; %#ok<NASGU>
            root = obj.root; %#ok<NASGU,PROP>
            timestamp = datestr(now); %#ok<NASGU>
            if nargin<2
                filename = fullfile(pwd,'product_cache.mat');
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

        function downstream = downstreamDependencies(c,prodkey,subset)
        % Identifies products which depend on the specified one from the
        % (optional) supplied subset.
            if nargin<3 || isempty(subset)
                subset = c.allProductKeys;
            end
            % First remove all upstream products
            upstream = c.allUpstreamProducts(prodkey);
            subset = setdiff(subset,upstream);
            isdownstream = false(size(subset));
            for i=1:numel(subset)
                upstream = c.allUpstreamProducts(subset{i});
                isdownstream(i) = ismember(prodkey,upstream);
            end
            downstream = subset(isdownstream);
        end
        
        function pk = allDownstreamProducts(c,prodkey)
        % Identifies components downstream of the specified one.
            if iscell(prodkey)
                pk = {};
                for i=1:numel(prodkey)
                    if ~ismember(prodkey{i},pk)
                        a = c.downstreamDependencies(prodkey{i});
                        pk = unique([pk ; a]);
                    end
                end
                return;
            end    
            pk = c.downstreamDependencies(prodkey);
        end

        function p = allProductKeys(obj)
            if ~isempty(obj.productKeys)
                p = obj.productKeys;
                return;
            end
            compfolder = fullfile(obj.root,'config','products');
            tic;
            p = mt_filesearch(compfolder,true,'.xml');
            pattern = ['.*config\' filesep 'products\' filesep '(?<prodname>.*).xml'];
            n = regexp(getabsx(p),pattern,'names');
            e = find(cellfun(@isempty,n));
            for i=1:numel(e)
                warning('mwood:prod:noprod','Can''t identify product key in: %s',getabs(p(i)));
            end
            n = [n{:}];
            p = {n.prodname}';
            p = strrep(p,'\','/');
            fprintf('Found %d components in %f seconds\n',numel(p),toc);
            obj.productKeys = p;
            obj.products = cell(size(p));
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
        
    end
        
    methods (Access=private)
        
        function loadProduct(obj,prodkey,ind)
            p = productReader(prodkey);
            p.root = obj.root;
            try
                p.loadProduct;
            end
            obj.products{ind} = p;
        end
        
        function c = getProduct(obj,ind)
            if isempty(obj.products{ind})
                n = obj.allProductKeys;
                obj.loadProduct(n{ind},ind);
            end
            c = obj.products{ind};
        end
        
        function printed = printComponentSubtree(obj,compinfo,indent,already_printed)
            fprintf('%s%s\n',indent,compinfo.componentName);
            already_printed = [ already_printed ; {compinfo.componentName} ];
            for i=1:numel(compinfo.dependsOn)
                c = obj.findComponent(compinfo.dependsOn{i});
                if ~ismember(c.componentName,already_printed)
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
                filename = fullfile(pwd,'product_cache.mat');
            end
            comps = load(filename);
            obj = ComponentAnalysis;
            obj.components = comps.comps;
            obj.productKeys = comps.names;
            obj.root = comps.root;
            fprintf('Cache created %s for %s\n',comps.timestamp,comps.root);
        end
    end
end

