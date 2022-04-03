function runeditordoc

f = editordoc;
[d,n] = fileparts(f);
try
    sr = sbroot(f);
catch
    sr = fileparts(matlabroot);
end
tr = fullfile(sr,'matlab','test');
do_runsuite = strncmp(d,tr,numel(tr)) && n(1)=='t';
cdeditordoc;
if do_runsuite
    cmd = sprintf('runtests(''%s.m'')',n);
else
    [d,p] = fileparts(d);
    while p(1)=='@' || p(1)=='+'
        n = [p(2:end) '.' n]; %#ok<AGROW>
        [d,p] = fileparts(d);
    end
    cmd = n;
end
fprintf('Calling <a href="matlab:%s">%s</a>\n',cmd,cmd);
eval(cmd);

end
