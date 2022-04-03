function [ok,output] = compile_if_required(filename)

f = mtfilename(filename);
[module,rel] = find_module_folder(f);

ok = false(size(f));

for i=1:numel(f)
    [d2,n] = fileparts(rel{i});
    d1 = relativepath(module(i),[sbroot '/matlab']);

    restore_dir = mt_cd(getabs(module(i)));

    dots = sum(d1=='/');
    dots = repmat('../',1,dots+1);
    obj_file = [dots 'derived/glnxa64/obj/' d1 '/' d2 '/' n '.o'];

    fprintf('Compiling: %s...\n',rel{i});
    [status,output] = system(['sbmake ' obj_file]);

    ok(i) = status==0;
    
    if ok(i)
        fprintf('Successfully compiled: %s\n',rel{i});
    else
        fprintf('Failed to compile: %s\n',rel{i});
        last_compiler_error(output);
    end

    delete(restore_dir);
end

end
