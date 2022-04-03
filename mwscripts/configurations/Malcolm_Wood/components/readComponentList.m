function comps = readComponentList(cluster)
% Returns the list of components specified by a ComponentList file
%
% comps = readComponentList('mycluster')
%
% Runs "ch ctb" for the file in matlab/config/ctb/clusters/mycluster.xml
% and returns the list of components as a cell array of strings.

if ~any(cluster=='.')
    file = ['matlab/config/ctb/clusters/' cluster '.xml'];
else
    file = cluster;
end

if ~exist(file,'file')
    error('mwood:tools:ctb','ComponentList file not found: %s\n',file);
end

[status,output] = system(['mw ch ctb -file ' file]);
if status~=0
    error('mwood:tools:ctb','Failed to get CTB list: %s\n',output);
end

lines = mt_tokenize(output,char(10));
comps = regexp(lines,'^  (.*)$','tokens');
comps = [ comps{:} ];
comps = [ comps{:} ];
comps = comps(:);
