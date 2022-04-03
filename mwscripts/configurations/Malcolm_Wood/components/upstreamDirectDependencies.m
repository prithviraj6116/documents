function comps = upstreamDirectDependencies(c,compname,target)
% Finds upstream components which depend directly on a specified one
%
% comps = upstreamDirectDependencies(compname,target)
    comps = {};
    allcomps = c.allUpstreamComponents(compname);
    for i=1:numel(allcomps)
        thiscomp = c.findComponent(allcomps{i});
        if ismember(target,thiscomp.dependsOn)
            comps{end+1} = thiscomp.componentName; %#ok<AGROW>
        end
    end
    comps = comps(:);
end