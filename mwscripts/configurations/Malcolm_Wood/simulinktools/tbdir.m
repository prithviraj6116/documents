function tbdir
try
    r = sbroot;
catch
    disp('Not in a sandbox.  Using MATLAB root.');
    r = fileparts(matlabroot);
end
cd(fullfile(r,'matlab','toolbox','simulink','simulink'));
disp(pwd);
end