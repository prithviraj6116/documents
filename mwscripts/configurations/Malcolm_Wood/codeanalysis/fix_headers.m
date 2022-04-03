function fix_headers(mainheader,subheader,dry_run)
% Fixes downstream files after removing a #include
%
% fix_headers(mainheader,subheader)
%
% After removing "#include subheader" from mainheader, call this function
% to fix all files which include mainheader.  It is assumed that mainheader
% already compiles standalone.

r = sbroot;

hpp = header_search(mainheader,'hpp',true);
fprintf('%d headers found\n',numel(hpp));
for i=1:numel(hpp)
    f = fullfile(r,'matlab',hpp{i});
    if dry_run
        target = '/tmp/out.txt';
    else
        target = f;
    end
    try
        if insert_header(f,subheader,mainheader,target);
            fprintf('Inserted in %s\n',hpp{i});
        else
            fprintf('Already present in %s\n',hpp{i});
        end
    catch
        fprintf('FAILED to insert in %s\n',hpp{i});
    end
end

cpp = header_search(mainheader,'cpp',true);
for i=1:numel(cpp)
    f = fullfile(r,'matlab',cpp{i});
    if dry_run
        target = '/tmp/out.txt';
    else
        target = f;
    end
    try
        sbcc(f);
        fprintf('Not needed in %s\n',cpp{i});
    catch
        try
            if insert_header(f,subheader,mainheader,target);
                fprintf('Inserted in %s\n',cpp{i});
            else
                fprintf('Already present in %s\n',cpp{i});
            end
        catch
            fprintf('FAILED to insert in %s\n',cpp{i});
        end
    end
end


end


