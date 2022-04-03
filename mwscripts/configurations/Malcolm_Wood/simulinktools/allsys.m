function s = allsys
%ALLSYS Returns the names of all loaded block diagrams
%
% s = allsys
%
% s is a cell array of strings

s = find_system('SearchDepth',0,'type','block_diagram');

