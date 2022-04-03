function buildlistProblemReport(c,cfg)
% Generates a report showing problems with a cluster's CTB list
%
% buildlistProblemReport(c,cfg)
%
% c is a ComponentAnalysis instance
% cfg specifies the cluster, or its configuration file

ctb = readBuildList(cfg);
comps = buildlistMatcher(c.componentNames,ctb);

allup = c.allUpstreamComponents(comps);
alldown = c.allDownstreamComponents(comps);
both = intersect(allup,alldown);
not_built = setdiff(both,comps);
fprintf('%d problems found\n',numel(not_built))

up_from = cell(size(not_built));
down_from = cell(size(not_built));
for i=1:numel(not_built)
    % Why is this component needed?
    nb = not_built{i};
    required_by = c.allDownstreamComponents(nb);
    required_by = intersect(required_by,comps);
    up_from{i} = required_by{1};
    required_by = c.allUpstreamComponents(nb);
    required_by = intersect(required_by,comps);
    down_from{i} = required_by{1};
    fprintf('%s: %s, %s\n',not_built{i},down_from{i},up_from{i});
end


f = fopen(mtfilename('comps_problem_report.html'),'wt',true);
closefile = onCleanup(@() fclose(f));

fprintf(f,'<html><head><title>Components</title></head>\n');
fprintf(f,'<body>\n');

fprintf(f,'<table>\n');
fprintf(f,'<tr><th>Component</th><th>Downstream from</th><th>Upstream from</th></tr>\n');

for i=1:numel(not_built)
    fprintf(f,'<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n',not_built{i},down_from{i},up_from{i});
end


fprintf(f,'</table>\n');
fprintf(f,'</body>\n');
fprintf(f,'</html>\n');
delete(closefile)

web comps_problem_report.html