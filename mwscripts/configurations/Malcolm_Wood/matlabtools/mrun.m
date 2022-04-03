function mrun(f,p)
% mrun test/toolbox/simulink/sl_loadsave_system/tFileFormat.m
% mrun test/toolbox/simulink/sl_loadsave_system/tFileFormat.m tFileFormat/lvlTwo_RunMe
% mrun g1234567   % all BPed tests for geck (in this sandbox)

if f(1)=='g'
    qerunbptest(f);
    i_run_bp_tests(str2double(f(2:end)));
    return;
end

[d,n] = fileparts(f);
i_cd(d);

if nargin>1
    if any(p=='/')
        t = p;
    else
        t = [n '/' p];
    end
else
    t = n;
end

runtests(t);

end

function i_run_bp_tests(g)
bpdHandle = bpdData.GlobalBPData;
bpnum = bpdHandle.lookup('gnum',g);

for i=1:numel(bpnum)
    bpinfo = bpdHandle.bpdlist(bpnum(i));
    i_cd(bpinfo.testdir);
    runtests(bpinfo.testpoint);
end

end

function i_cd(f)
if strncmp(f,'test/',5)
    f = fullfile(sbroot,'matlab',f);
elseif strncmp(f,'matlab/',7)
    f = fullfile(sbroot,f);
end
cd(f);
end