function jobarchivedir
% Changes to the job archive folder for the current sandbox.
try
    r = sbroot;
catch
    disp('Not in a sandbox.  Using MATLAB root.');
    r = fileparts(matlabroot);
end
fprintf('Return to: <a href="matlab:cd %s">%s</a>\n',pwd,pwd);
startdir = pwd;
try
    cd(r);
    [status,output] = system('sbver');
    if status
        error('mwood:tools:sbver','sbver failed: %s',output);
    end
    match = regexp(output,'SyncFrom: (?<jobarchive>[^\s*]*)','names');
    if isempty(match)
        error('mwood:tools:sbver','sbver output unrecognised: %s',output);
    end
    cd(match.jobarchive);
    fprintf('pwd now: <a href="matlab:cd %s">%s</a>\n',pwd,pwd);
catch E
    cd(startdir);
    rethrow(E);
end
end