function gdb_index

[~,dirname] = fileparts(tempname);
dirname = ['/tmp/gdb_index_' dirname];
mkdir(dirname);

startdir = cd(dirname);
restoredir = onCleanup(@() cd(startdir));

fprintf('Creating index for %s\n',matlabroot);
pid = feature('getpid');
gdbcmd = sprintf('gdb --pid=%d -ex "save gdb-index ." -ex "detach" -ex "quit"',pid);
tic
[status,out] = system(gdbcmd);
toc;

if status~=0
    error('mwood:gdb_index:SaveIndexFailed','Failed: %s',out);
end

r = matlabroot;
fprintf('Index created in %s\n',dirname);

d = dir([dirname '/*.gdb-index']);

fmt = 'objcopy --add-section .gbd_index=%s --set-section-flags .gdb_index=readonly %s %s';
for i=1:numel(d)
    indexfile = d(i).name;
    basename = indexfile(1:end-14); % string .dbg.gdb-index
    symfile = fullfile(r,'bin',lower(computer),basename);
    if ~exist(symfile,'file')
        fprintf('Symbol file not found: %s\n',symfile);
    else
        cmd = sprintf(fmt,indexfile,symfile,symfile);
        disp(cmd);
        [status,out] = system(cmd);
        if status~=0
            fprintf('Failed for %s: %s\n',symfile,out);
        end
    end
end

delete(restoredir);