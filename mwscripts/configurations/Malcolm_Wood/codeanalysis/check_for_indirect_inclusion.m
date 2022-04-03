function included = check_for_indirect_inclusion(filename,header_pattern)

prep = preprocess(filename);
[status,output] = system(['cat ' prep ' | grep ' header_pattern]);
%if status~=0
%    error('Malcolm:preproc:grep','%s',output);
%end

included = ~isempty(output);
