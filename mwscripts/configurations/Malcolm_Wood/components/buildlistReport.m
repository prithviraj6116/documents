function buildlistReport(c,cfg,comps)
% Generates a report showing which of a set of component are built in a cluster
%
% buildlistReport(c,cfg,comps)
%
% c is an instance of ComponentAnalysis
% cfg specifies the cluster, or its configuration file
% comps is an optional cell array of the names of components of interest
%
% The report lists:
%  The components built by the cluster, and the CTB patterns which match each.
%  The CTB patterns in the cluster's config file, and the components they match
%  Any components in the specified list that are not built by the cluster

ctb = readBuildList(cfg);
got_comps = true;
if nargin<3 || isempty(comps)
    comps = c.matchingComponentNames(ctb);
    got_comps = false;
end
comps = sort(comps);

[builtcomps,unmatched,matchind] = buildlistMatcher(comps,ctb);

f = fopen(mtfilename('comps_report.html'),'wt',true);
c = onCleanup(@() fclose(f));

fprintf(f,'<html><head><title>Components</title></head>\n');
fprintf(f,'<body>\n');

% List all the built components
fprintf(f,'<table>\n');
fprintf(f,'<tr><th>Components (%d)</th><th>Matched by</th></tr>\n',numel(builtcomps));
for i=1:numel(matchind)
    mi = matchind{i};
    if ~isempty(mi)
        desc = '';
        for k=1:numel(mi)
            desc = [desc sprintf('%s (%d)<br>',ctb{mi(k)},mi(k))]; %#ok<AGROW>
        end
        fprintf(f,'<tr><td>%s</td><td>%s</td></tr>\n',comps{i},desc);
    end
end
fprintf(f,'</table>\n');

% List the patterns
fprintf(f,'<table>\n');
fprintf(f,'<tr><th>Patterns (%d)</th><th>Matching components</th></tr>\n',numel(ctb));
for i=1:numel(ctb)
    fprintf(f,'<tr><td>%d: %s</td>\n',i,ctb{i});
    matchcomps = {};
    for k=1:numel(matchind)
        if ~isempty(matchind{k}) && matchind{k}==i
            matchcomps = [ matchcomps ; comps(k) ]; %#ok<AGROW>
        end
    end
    matchcomps = sprintf('%s ',matchcomps{:});
    fprintf(f,'<td>%s </td></tr>\n',matchcomps);
end

if got_comps
    % List those unmatched by any pattern
    unmatched = sort(unmatched);
    allunmatched = sprintf('%s<br> ', unmatched{:});
    fprintf(f,'<p><b>Not building: </b><br> %s</p>',allunmatched);
end

fprintf(f,'</body>\n');
fprintf(f,'</html>\n');
delete(c)

web comps_report.html