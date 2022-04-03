function profgen2(pre,cmd,root)
% Generates a report of the differences between profiler results for
% running the specified command in the interpreter and in LXE.
%
% profgen2(pre,cmd);
% profgen2(pre,cmd,sbroot);
%
% "pre" is a command to be executed before profiling starts.
% "cmd" is the command to be profiled.


if nargin<3
    root = fileparts(matlabroot);
end

full_cmd = [pre ',profile on,' cmd ',p = profile(''info''),save prof_interp.mat p,exit'];
sys_cmd = ['sb -s ' root ' -r "' full_cmd '"'];
system(sys_cmd);

full_cmd = [pre ',profile on,' cmd ',p = profile(''info''),save prof_lxe.mat p,exit'];
sys_cmd = ['sb -lxe s ' root ' -r "' full_cmd '"'];
system(sys_cmd);

p_interp = load('prof_interp.mat');
p_lxe = load('prof_lxe.mat');
profdiff(p_interp.p,p_lxe.p);

end