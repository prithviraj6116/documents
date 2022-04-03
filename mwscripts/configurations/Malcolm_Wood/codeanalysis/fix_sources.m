function fix_sources(removed_header,dry_run)
% Fixes source files files after removing an upstream #include
%
% fix_sources(removed_header)

if nargin<2
    dry_run = false;
end

cpp = find_files_to_compile;
disp('Filed to be compiled:');
disp(cpp);
%cpp = mt_filesearch(pwd,true,'.cpp');
for i=1:numel(cpp)
    f = cpp{i};%relativepath(cpp(i),pwd);
    if dry_run
        target = '/tmp/out.txt';
    else
        target = f;
    end
    ok = compile_if_required(f);
    if ok
        fprintf('Not needed in %s\n',f);
    else
        try
            if insert_header(f,removed_header,'',target);
                fprintf('Inserted in %s\n',f);
                if ~dry_run
                    ok = compile_if_required(f);
                    if ~ok
                        fprintf('  STILL FAILS TO COMPILE: %s\n',f);
                    end
                end
            else
                fprintf('Already present in %s\n',f);
            end
        catch
            fprintf('FAILED to insert in %s\n',f);
        end
    end
end


end


