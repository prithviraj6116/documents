function files = find_files_to_compile
% fine_files_to_compile - Returns a list of files that need to be re-compiled
%
%  files = find_files_to_recompile
%
% Checks which source files in the current module do not have up-to-date
% .o files, and thus need to be compiled.

[status,out] = system('sbmake build -n');

if status~=0
    error('mwood:tools:files_to_compile','%s',out);
end

comp = regexp(out,'echo Compiling ([^\s]*.cpp)','tokens');
if isempty(comp)
    % Up to date
    files = {};
    return;
end
files = vertcat(comp{:});

b = mt_endswith(files,'modver.cpp');
files = files(~b);

files = strcat(sbroot,'/matlab/',files);
files = mtfilename(files);

files = relativepathx(files,pwd);

end


