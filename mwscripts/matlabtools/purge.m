function purge
%     bdclose all;clear all;clc;dbclear all;
%     rmdir('/home/ppatil/Downloads/debug1/slCache', 's');
    mkdir('/home/ppatil/Downloads/debug1/slCache/sim');
    mkdir('/home/ppatil/Downloads/debug1/slCache/codegen');
    set_param(0, 'CacheFolder','/home/ppatil/Downloads/debug1/slCache/sim');
    set_param(0, 'CodeGenFolder','/home/ppatil/Downloads/debug1/slCache/codegen');

end
