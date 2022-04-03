function p4edit(filename,action)

if nargin<1
    filename = editordoc;
end

if nargin<2
    action = 'edit';
end

if iscell(filename)
    for i=1:numel(filename)
        p4edit(filename{i},action);
    end
    return;
end

res = which(filename);
if isempty(res)
    res = fullfile(pwd,filename);
    if ~exist(res,'file')
        res = filename;
        if ~exist(res,'file')
            error('mwood:tools:p4edit','Not found: %s',filename);
        end
    end
end

try
    r = sbroot;
catch
    % Not in any sandbox.  Use matlabroot (and we'll throw an error if the
    % file we're editing isn't under the current matlabroot).
    disp('Not in a sandbox.  Using matlabroot');
    r = matlabroot;
end
if ~strncmp(res,r,numel(r))
    error('mwood:tools:p4edit','Sandbox doesn''t match: %s, %s',res,r);
end

[d,n,e] = fileparts(res);
pfile = fullfile(d,[n '.p']);
if strcmp(e,'.p') || exist(pfile,'file')
    fprintf('Deleting .p file.  Call <a href="matlab:rehash toolboxcache">rehash toolboxcache</a> after this.\n');
    delete(pfile);
    e = '.m';
end

startdir = cd(d);
restoredir = onCleanup(@() cd(startdir));

[~,output] = system(sprintf('p4 %s %s%s',action,n,e));
disp(strtrim(output));

end
