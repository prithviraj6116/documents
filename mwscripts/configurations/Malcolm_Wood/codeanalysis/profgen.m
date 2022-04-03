function profgen(cmd,root)
% Generates a report of the differences between profiler results for
% running the specified command in the interpreter and in LXE.
%
% profgen(cmd);  % executes the supplied command
% profgen(cmd,sbroot);


if nargin<2
    root = fileparts(matlabroot);
end

full_cmd = ['profile on,' cmd ',p = profile(''info''),save prof_interp.mat p,exit'];
sys_cmd = ['sb -s ' root ' -r "' full_cmd '"'];
system(sys_cmd);

full_cmd = ['profile on,' cmd ',p = profile(''info''),save prof_lxe.mat p,exit'];
sys_cmd = ['sb -lxe s ' root ' -r "' full_cmd '"'];
system(sys_cmd);

p_interp = load('prof_interp.mat');
p_lxe = load('prof_lxe.mat');
profdiff(p_interp.p,p_lxe.p);

end