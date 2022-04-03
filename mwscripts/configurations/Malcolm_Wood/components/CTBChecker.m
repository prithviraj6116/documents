classdef CTBChecker < handle
    properties
        cluster;
        c;
        ctb;
        all_buy;
        bought_component_is_problem;
        built_component_is_problem;
        f = 1; % stdout initially
        ignore_list;
    end
    methods
        function obj = CTBChecker(ca,cl)
            obj.c = ca;
            obj.cluster = cl;
            tic
            obj.findComponents;
            obj.findProblems;
            t = toc;
            fprintf('Analysis completed in %f seconds\n',t);
        end
        function findComponents(obj)
            raw_ctb = readBuildList(obj.cluster,obj.c.root);
            obj.readIgnoreList;
            fprintf('Found %d entries in the CTB file\n',numel(raw_ctb));
            raw_ctb = strcat('^',raw_ctb,'$');
            obj.ctb = obj.c.matchingComponentNames(raw_ctb);
            fprintf('Resolved %d components to build\n',numel(obj.ctb));
            all_build_or_buy = obj.c.allUpstreamComponents(obj.ctb);
            obj.all_buy = setdiff(all_build_or_buy,obj.ctb);
            fprintf('Found %d components to buy\n',numel(obj.all_buy));
        end
        function findProblems(obj)
            obj.bought_component_is_problem = false(size(obj.all_buy));
            obj.built_component_is_problem = zeros(size(obj.ctb));
            for i=1:numel(obj.all_buy)
                if ismember(obj.all_buy{i},obj.ignore_list)
                    continue;
                end
                bc = obj.c.findComponent(obj.all_buy{i});
                m = ismember(bc.dependsOn,obj.ctb);
                if any(m)
                    % Problem component.  Bought, but depends on components that
                    % we're building
                    list = sprintf(' %s',bc.dependsOn{m});
                    fprintf('Problem component found: %s (depends on %s)\n',bc.componentName,list);
                    d = obj.c.downstreamDependencies(bc.componentName,obj.ctb);
                    [~,ctb_ind] = ismember(d,obj.ctb);
                    obj.built_component_is_problem(ctb_ind) = obj.built_component_is_problem(ctb_ind) + 1;
                    obj.bought_component_is_problem(i) = true;
                end
            end
            problem_count = sum(obj.bought_component_is_problem);
            fprintf('%d problem components found\n',problem_count);
            fprintf('%d problem-causing components found\n',sum(obj.built_component_is_problem~=0));
        end
        function reportAll(obj)
            obj.reportBuildListProblems;
            for i=1:numel(obj.all_buy)
                if obj.bought_component_is_problem(i)
                    obj.reportComponentProblems(obj.all_buy{i});
                end
            end
        end
        function reportBuildListProblems(obj)
            [cpcount,cpind] = sort(obj.built_component_is_problem);
            ctb_problems = obj.ctb(cpind);
            ctb_problems = ctb_problems(cpcount~=0);
            cpcount = cpcount(cpcount~=0);
            for i=numel(ctb_problems):-1:1
                fprintf('CTB: %s uses %d problem components\n',ctb_problems{i},cpcount(i));
            end
            t = toc;
            fprintf('Analysis took %f seconds\n',t);
        end
        function reportComponentProblems(obj,comp)
            if ismember(comp,obj.all_buy)
                % Bought component.  Check for upstream components in the
                % CTB list.
                bc = obj.c.findComponent(comp);
                m = ismember(bc.dependsOn,obj.ctb);
                if any(m)
                    % Depends on components that we're building.
                    d = bc.dependsOn(m);
                    if obj.f~=1
                        % HTML format
                        d = strcat('<a href="#', d, '">', d, '</a>');
                    end
                    fprintf(obj.f,'Problem with bought component: %s\n',comp);
                    fprintf(obj.f,'  Depends on built component %s\n',d{:});
                    % Report the components that cause us to buy this one.
                    d = obj.c.immediateDownstreamComponents(comp,obj.ctb);
                    if obj.f~=1
                        % HTML format
                        d = strcat('<a href="#', d, '">', d, '</a>');
                    end
                    if ~isempty(d)
                        fprintf(obj.f,'  Required directly by built component %s\n',d{:});
                    else
                        d = obj.c.immediateDownstreamComponents(comp,obj.all_buy);
                        fprintf(obj.f,'  Required indirectly via bought component %s\n',d{:});
                    end
                else
                    fprintf(obj.f,'No problems found for %s\n',comp);
                end
            elseif ismember(comp,obj.ctb)
                % Built component.  Check for upstream bought components that are
                % downstream of other built components.
                [~,ind] = ismember(comp,obj.ctb);
                if obj.built_component_is_problem(ind)~=0
                    fprintf(obj.f,'Built component %s depends on %d problem components\n',...
                        comp,obj.built_component_is_problem(ind));
                    ups = obj.c.allUpstreamComponents(comp);
                    prob = intersect(obj.all_buy(obj.bought_component_is_problem),ups);
                    if obj.f~=1
                        % HTML format
                        prob = strcat('<a href="#', prob, '">', prob, '</a>');
                    end
                    fprintf(obj.f,'  Depends on %s\n',prob{:});
                else
                    fprintf(obj.f,'No problems found for built component %s\n',comp);
                end
            else
                fprintf(obj.f,'Component %s is neither built nor bought\n',comp);
            end
        end
        function writeHTML(obj,filename)
            tic
            mf = mtfilename(filename);
            obj.f = fopen(getabs(mf),'w','native','utf-8');
            closefile = onCleanup(@() fclose(obj.f));
            fprintf(obj.f,'<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">\n');
            fprintf(obj.f,'<title>Component Report</title></head>\n');
            fprintf(obj.f,'<body><style> .tab { margin-left: 40px; } </style>\n');
            fprintf(obj.f,'<h1>Component Report</h1>\n');
            fprintf(obj.f,'<p><ul><li>Building %d components (<a href="#buildlist">go</a>)</li>\n',numel(obj.ctb));
            fprintf(obj.f,'<li>Buying %d components (<a href="#buylist">go</a>)</li>\n',numel(obj.all_buy));
            fprintf(obj.f,'<li>%d problem components (<a href="#problemlist">go</a>)</li>\n',sum(obj.bought_component_is_problem));
            fprintf(obj.f,'<li><a href="problems">Problem summaries</li>\n');
            
            fprintf(obj.f,'<h2><a name="buildlist">Build List (%d components)</h2>\n',numel(obj.ctb));
            fprintf(obj.f,'<p class="tab"><ol class="tab">\n');
            for i=1:numel(obj.ctb)
                writeComponentHTML_Build(obj,i);
            end
            fprintf(obj.f,'</ol></p>\n');
            
            fprintf(obj.f,'<h2><a name="buylist">Buy List (%d components)</h2>\n',numel(obj.all_buy));
            fprintf(obj.f,'<p class="tab"><ol class="tab">\n');
            for i=1:numel(obj.all_buy)
                writeComponentHTML_Buy(obj,i);
            end
            fprintf(obj.f,'</ol></p>\n');
            
            fprintf(obj.f,'<h2><a name="problemlist">Problem List (%d components)</h2>\n',sum(obj.bought_component_is_problem));
            fprintf(obj.f,'<p class="tab"><ol class="tab">\n');
            for i=1:numel(obj.all_buy)
                if obj.bought_component_is_problem(i)
                    writeComponentHTML_Buy(obj,i);
                end
            end
            fprintf(obj.f,'</ol></p>\n');
            
            fprintf(obj.f,'<h2><a name="problems">Problem summaries</h2>');
            for i=1:numel(obj.ctb)
                if obj.built_component_is_problem(i)
                    writeComponentHTML_Problems(obj,obj.ctb{i});
                end
            end
            for i=1:numel(obj.all_buy)
                if obj.bought_component_is_problem(i)
                    writeComponentHTML_Problems(obj,obj.all_buy{i});
                end
            end
            fprintf(obj.f,'</body></html>\n');
            delete(closefile);
            t = toc;
            fprintf('Report generated in %f seconds\n',t);
        end
        function writeProblemComponentList(obj,filename)
            mf = mtfilename(filename);
            writetextfile(mf,obj.all_buy(obj.bought_component_is_problem));
            fprintf('Write %s\n',getabs(mf));
        end
    end
    methods (Access=private)
        function writeComponentHTML_Build(obj,i)
            comp = obj.ctb{i};
            if obj.built_component_is_problem(i)
                msg = ' <font style="color:red;">!</font>';
                fprintf(obj.f,'<li><a href="#%s">%s</a>%s</li>\n',comp,comp,msg);
            elseif ismember(comp,obj.ignore_list)
                fprintf(obj.f,'<li>%s <font style="color:green;">i</font>',comp);
            else
                fprintf(obj.f,'<li>%s <font style="color:green;">%s</font>',comp,char(10004)); % tick
            end
        end
        function writeComponentHTML_Buy(obj,i)
            comp = obj.all_buy{i};
            if obj.bought_component_is_problem(i)
                msg = ' <font style="color:red;">!</font>';
                fprintf(obj.f,'<li><a href="#%s">%s</a>%s</li>\n',comp,comp,msg);
            elseif ismember(comp,obj.ignore_list)
                fprintf(obj.f,'<li>%s <font style="color:green;">i</font>',comp);
            else
                fprintf(obj.f,'<li>%s <font style="color:green;">%s</font>',comp,char(10004)); % tick
            end
        end
        function readIgnoreList(obj)
            [~,cl] = fileparts(obj.cluster);
            got_ignore_list = true;
            ignore_list_file = fullfile(pwd,[cl '_ignore_list.txt']);
            if ~exist(ignore_list_file,'file')
                ignore_list_file = fullfile(fileparts(mfilename('fullpath')),[cl '_ignore_list.txt']);
                if ~exist(ignore_list_file,'file')
                    fprintf('No ignore list found (%s)\n',ignore_list_file);
                    got_ignore_list = false;
                end
            end
            if got_ignore_list
                ig = mtfilename(ignore_list_file);
                raw_ignore_list = readtextfile(ig);
                obj.ignore_list = obj.c.matchingComponentNames(raw_ignore_list);
                fprintf('Found %d entries (matching %d components) in ignore list (%s)\n',...
                    numel(raw_ignore_list),numel(obj.ignore_list),ignore_list_file);
            end
        end
        function writeComponentHTML_Problems(obj,comp)
            fprintf(obj.f,'<h4><a name="%s">%s</h4>\n',comp,comp);
            fprintf(obj.f,'<pre>');
            obj.reportComponentProblems(comp);
            fprintf(obj.f,'</pre>\n');
        end
    end
end