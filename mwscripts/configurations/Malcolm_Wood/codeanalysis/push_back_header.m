function push_back_header(header_being_removed, header_being_cleaned)
% push_back_header - Fixes downstream code after removing a #include
%
%  push_back_header(header_being_removed, header_being_cleaned)
%
% Call this function after removing:
%    #include header_being_removed.hpp
% from header_being_cleaned.hpp.
%
% This function finds all downstream code that #includes
% header_being_cleaned.hpp and updates it so that it will still compile.
%
% The process is:
%  1) Find, using grep, all headers
%       which #include header_being_cleaned.hpp
%  2) Where these don't compile standalone, add #include header_being_removed.hpp.
%  3) Find, using grep, all C++ files
%       which #include header_being_cleaned.hpp.
%  4) Try compiling those.  To any which fail to compile,
%       add #include header_being_removed.hpp
%
% Before running this function MAKE SURE THAT header_being_cleaned.hpp
% compiles standalone.
%
% header_being_removed much include any folder name that is required to
% access it from other folders (e.g. sl_cmds/load_mdl.hpp) but the function
% will find code in the same folder which includes it directly
% (e.g. #include load_mdl.hpp).  Don't use this function if there are
% multiple headers with the same name in different folders.

% Find headers that include the one being cleaned.
[~,n,e] = fileparts(header_being_cleaned);
hpp = hppgrep(['\<' n '\' e '\>']);
% In each header we find, include the one we removed.
for i=1:numel(hpp)
    h = hpp{i};
    try
        make_compile_standalone_knownsymbols(h);
    catch E
        % Couldn't find other headers make it compile standalone.
        % insert the one we just removed.
        insert_header(h,header_being_removed,[],header_being_cleaned)
    end
end

% Find sources which include the one being cleaned.
cpp = header_search(header_being_cleaned,'cpp');
% Write this list to a text file.
restoredir = mt_cd(sbroot);
writetextfile(mtfilename('sources_to_compile.txt'),cpp);
% Compile these source files, fixing them where necessary.
compile_sources(cpp,header_being_removed,header_being_cleaned);

end
