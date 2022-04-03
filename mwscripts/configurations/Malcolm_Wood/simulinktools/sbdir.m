function sbdir
try
    r = sbroot;
catch
    disp('Not in a sandbox.  Using MATLAB root.');
    r = fileparts(matlabroot);
end
cd(r);
disp(pwd);
end