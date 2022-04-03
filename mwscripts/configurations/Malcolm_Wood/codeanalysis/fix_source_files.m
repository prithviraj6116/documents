function fix_source_files(files)

for i=1:numel(files)
    filename = files{i};
    disp(filename);
    try
        sbcc(filename,false);
        fprintf('%s compiled without error\n',filename);
    catch E
        modified = fix_using_compiler_output(last_compiler_error,false); % non-interactive
        if ~modified
            fprintf('%s failed to compile.  No fixes found\n',filename);
            disp(E.message);
        end
    end
end
