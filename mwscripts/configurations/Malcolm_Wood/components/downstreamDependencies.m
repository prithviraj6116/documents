function downstream = downstreamDependencies(c,component,subset)
% Identifies components downstream of the specified one.
    if nargin<3 || isempty(subset)
        subset = c.componentNames;
    end
    % First remove all upstream components
    upstream = c.allUpstreamComponents(component);
    subset = setdiff(subset,upstream);
    isdownstream = false(size(subset));
    for i=1:numel(subset)
        upstream = c.allUpstreamComponents(subset{i});
        isdownstream(i) = ismember(component,upstream);
    end
    downstream = subset(isdownstream);
end