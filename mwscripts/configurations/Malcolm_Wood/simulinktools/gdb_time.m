function gdb_time

pid = feature('getpid');
gdbcmd = sprintf('gdb --pid=%d -ex "detach" -ex "quit"',pid);
tic
[status,out] = system(gdbcmd);
toc;
if status~=0
    error('mwood:gdb_index:SaveIndexFailed','Failed: %s',out);
end
