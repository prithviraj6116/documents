function testdir
try
    r = sbroot;
catch
    disp('Not in a sandbox.  Using MATLAB root.');
    r = fileparts(matlabroot);
end
cd(fullfile(r,'matlab','test','toolbox','simulink'));
disp(pwd);
end