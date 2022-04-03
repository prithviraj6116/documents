function printSegvStack(pid)

if isnumeric(pid)
    pid = num2str(pid);
end

file = ['~/matlab_crash_dump.' pid '-1'];
if isempty(Simulink.loadsave.resolveFile(file))
    if isempty(Simulink.loadsave.resolveFile(pid))
        error('mwood:tools:printSegvStack','Can''t find ''%s'' or ''%s''',file,pid);
    else
        file = pid;
    end
end       

printstack(mt_readtextfile(file),false);

end
