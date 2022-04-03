function sbcc(filename,open_on_failure)

[status,out] = system(['sbcc -mc ' filename]);
if status~=0
    m = regexp(out,'Total compile errors\s*:\s*(\d*)','tokens');
    if iscell(m) && ~isempty(m)
        m = m{1};
        if iscell(m) && ~isempty(m)
            n = str2double(m);
            if n==0
                % No compile errors.  Warnings only.
                return;
            end
        end
    end
    if nargin<2 || open_on_failure
        edit(filename);
    end
    last_compiler_error(out);
    error('mwood:preproc:sbcc','sbcc failed: %s',out);
end
count = regexp(out,'compile errors\s*:\s*(?<count>\d*)','names');
if isempty(count)
    last_compiler_error(out);
    error('mwood:preproc:sbcc','Unrecognised output: %s',out);
end
count = str2double(count.count);
if count~=0
    last_compiler_error(out);
    error('mwood:preproc:notstandalone','File does not compile: %s\n\n%s',filename,out);
end

end
