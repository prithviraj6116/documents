function tdbstack
% Displays a truncated call stack in a MATLAB test.

s = dbstack;
skip = false;
for i=1:numel(s)
    if strncmp(s(i).name,'TestRunner',10)
        return;
    end
    if strcmp(s(i).name,'FunctionHandleConstraint.invoke')
        skip = true;
    elseif strncmp(s(i).name,'Verifiable.',11)
        skip = false;
    end
    if ~skip
        fprintf('%s: %d\n',s(i).name,s(i).line);
    end
end