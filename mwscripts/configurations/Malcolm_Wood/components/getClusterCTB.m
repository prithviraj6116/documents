function ctb = getClusterCTB(cluster,mlroot)
% Given the name of a cluster, returns the components it builds.
%
% ctb = getClusterCTB(cluster,mlroot)
%
% Works both for clusters which have ComponentList XML files and for those
% which still use CTB patterns in their config files.
%
% e.g. ctb = getClusterCTB('Bslx');
%      ctb = getClusterCTB('Bslengine_integ',matlabroot);

if nargin<2 || isempty(mlroot)
    mlroot = fullfile(sbroot,'matlab');
end

if exist(fullfile(mlroot,'config','ctb','clusters',[cluster '.xml']),'file')
    % Found a ComponentList XML file.
    prevdir = cd(fileparts(mlroot));
    restoredir = onCleanup(@() cd(prevdir));
    ctb = readComponentList(cluster);
else
    % Need to look for an old-style CTB list in the cluster config file.
    patterns = readBuildList(cluster,mlroot);
    allcomps = ComponentAnalysis.allComponentNames(mlroot);
    ctb = buildlistMatcher(allcomps,patterns);
end