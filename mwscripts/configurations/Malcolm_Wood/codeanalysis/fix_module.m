function fix_module
% Best attempt at fixing compilation errors in a whole module

cmd = 'sbmake -distcc build DEBUG=1';
disp('Building...');
[~,out] = system(cmd);
disp('Build finished');
f = find_files_to_compile;
if ~isempty(f)
    last_compiler_error(out);
    fix_using_compiler_output(out);
    disp('Build failed');
else
    disp('Build succeeded');
end
