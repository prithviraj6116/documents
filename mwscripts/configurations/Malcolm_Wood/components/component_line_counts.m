try
    c = ComponentAnalysis.loadFromCache;
catch
    c = ComponentAnalysis;
    c.loadAllComponents;
end
up = c.upstreamComponentsFrom('simulink','matlab');
up{end,4} = []; % preallocate
for i=1:size(up,1)
    if ~isempty(up{i,2})
        continue;
    end
    cr = componentReader(up{i});
    [cpp,java,m] = cr.getCodeCount;
    up{i,2} = cpp;
    up{i,3} = java;
    up{i,4} = m;
end

f = fopen('comps.csv','w');
fprintf(f,'Component,C++ lines,Java lines,MATLAB lines,Total\n');
for i=1:size(up,1)
    s = sum([up{i,2:4}]);
    fprintf(f,'%s,%d,%d,%d,%d\n',up{i,1},up{i,2},up{i,3},up{i,4},s);
end
fclose(f);