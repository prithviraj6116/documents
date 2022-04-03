function [matched,unmatched,matchind] = buildlistMatcher(comps,ctb)
% Given a list of components and a list of "components to build" patterns,
% returns list indicating which components will be built and why.
%
% [matched,unmatched,matchind] = buildlistMatcher(comps,ctb)
%
% comps is a cell array of component names
% ctb is a list of "CTB" expressions as returned by readBuildList.
%
% Components which will be built are returned in "matched".
% Components which will not be built are returned in "unmatched".
% "matchind" is a cell array of numeric arrays indicating the "ctb" entries
% which match the corresponding component (empty for "unmatched" components).

matches = false(size(comps));
matchind = cell(size(comps));
for i=1:numel(ctb)
    m = regexp(comps,['^' ctb{i} '$']);
    m = ~cellfun(@isempty,m);
    matches = matches | m;
    for j=1:numel(comps)
        if m(j)
            matchind{j} = [ matchind{j} i ];
        end
    end
end
unmatched = comps(~matches);
matched = comps(matches);