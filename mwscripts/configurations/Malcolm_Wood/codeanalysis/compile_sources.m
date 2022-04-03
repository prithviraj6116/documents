function compile_sources(listfile,header_being_removed,header_being_cleaned,comment)
% Compiles the source files listed in a text file
%
% compile_sources(listfile,header_being_removed,header_being_cleaned,comment)
%
% If any listed files fail to compile, the header_being_removed is added
% immediately after the inclusion of header_being_cleaned.

if nargin<4
    comment = [];
end

cpp = readtextfile(mtfilename(listfile));
for i=1:numel(cpp)
    c = cpp{i};
    % Need to change to the folder for the module containing this file.
    c = fullfile(r,c);
    [d,f] = find_module_folder(c);
    restoredir = mt_cd(d);
    fprintf('Compiling %s\n',c);
    if ~compile_if_required(f)
        try
            insert_header(f,header_being_removed,comment,header_being_cleaned);
        catch E
            warning('mwood:tools:push',E.message);
            continue;
        end
        if ~compile_if_required(f)
            warning('mwood:tools:compile_sources','Still doesn''t compile: %s',f);
        end
    end
    delete(restoredir);
end

end
