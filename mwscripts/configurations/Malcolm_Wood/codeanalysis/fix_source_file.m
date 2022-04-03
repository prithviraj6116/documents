function fix_source_file(filename,message,interactive)

if nargin<2 || isempty(message)
    try
        sbcc(filename,false);
        fprintf('%s compiled without error\n',filename);
        return;
    catch E
        message = E.message;
    end
end

if nargin<2
    interactive = false;
end

modified = fix_using_compiler_output(message,interactive);

if ~modified
    fprintf('<a href="matlab:edit %s\n">edit %s</a>\n',filename,filename);
    rethrow(E);
end

try
    sbcc(filename);
catch E
    edit(filename);
    fprintf('<a href="matlab:fix_source_file %s\n">fix_source_file %s</a>\n',filename,filename);
    fprintf('<a href="matlab:edit %s\n">edit %s</a>\n',filename,filename);
    rethrow(E);
end
fprintf('%s compiled without error\n',filename);

end
