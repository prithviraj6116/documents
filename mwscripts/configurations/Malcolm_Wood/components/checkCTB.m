function checkCTB(c,cluster)
tic
raw_ctb = readBuildList(cluster);
fprintf('Found %d entries in the CTB file\n',numel(raw_ctb));
raw_ctb = strcat('^',raw_ctb,'$');
ctb = c.matchingComponentNames(raw_ctb);
fprintf('Resolved %d components to build\n',numel(ctb));
all_build_or_buy = c.allUpstreamComponents(ctb);
all_buy = setdiff(all_build_or_buy,ctb);
fprintf('Found %d components to buy\n',numel(all_buy));
is_problem = false(size(all_buy));
causes_problem = zeros(size(ctb));
for i=1:numel(all_buy)
    % Quick search
    bc = c.findComponent(all_buy{i});
    m = ismember(bc.dependsOn,ctb);
    if any(m)
        % Problem component.  Bought, but depends on components that
        % we're building
        d = bc.dependsOn(m);
        fprintf('Problem component found: %s\n',bc.componentName);
        if numel(d)>3
            fprintf('  Depends on %s\n',d{1:3});
            fprintf('    and %d others\n',numel(d)-3)
        else
            fprintf('  Depends on %s\n',d{:});
        end
        d = c.downstreamDependencies(bc.componentName,ctb);
        if numel(d)>3
            fprintf('  Required by %s\n',d{1:3});
            fprintf('    and %d others\n',numel(d)-3)
        else
            fprintf('  Required by %s\n',d{:});
        end
        [~,ctb_ind] = ismember(d,ctb);
        causes_problem(ctb_ind) = causes_problem(ctb_ind) + 1;
        is_problem(i) = true;
    end
end
problem_count = sum(is_problem);
fprintf('%d problem components found\n',problem_count);
fprintf('%d problem-causing components found\n',sum(causes_problem~=0));
[causes_problem,cpind] = sort(causes_problem);
ctb_problems = ctb(cpind);
ctb_problems = ctb_problems(causes_problem~=0);
causes_problem = causes_problem(causes_problem~=0);
for i=numel(ctb_problems):-1:1
    fprintf('CTB: %s uses %d problem components\n',ctb_problems{i},causes_problem(i));
end
t = toc;
fprintf('Analysis took %f seconds\n',t);
end