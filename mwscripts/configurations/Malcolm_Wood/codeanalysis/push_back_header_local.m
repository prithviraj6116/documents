function push_back_header_local(header_being_removed, header_being_cleaned)
% push_back_header_local - Fixes downstream code after removing a #include
%
%  push_back_header_local(header_being_removed, header_being_cleaned)
%
% Call this function after removing:
%    #include header_being_removed.hpp
% from a module-local header, header_being_cleaned.hpp.
%
% This function finds all code within the module that #includes
% header_being_cleaned.hpp and updates it so that it will still compile.
%
% The process is:
%  1) Find, using codesearch, all headers
%       which #include header_being_cleaned.hpp
%  2) Add #include header_being_removed.hpp to those.
%  3) Find, using codesearch, all C++ files
%       which #include header_being_cleaned.hpp.
%  4) Try compiling those.  To any which fail to compile,
%       add #include header_being_removed.hpp
%
% Steps 2 & 4 risk adding absurd-looking #includes to lots of files.
% This can't really be helped, without a much more advanced tool.  And it's
% worth remembering that these files ALREADY INCLUDED THE UNNECESSARY CODE.
%
% Before running this function MAKE SURE THAT header_being_cleaned.hpp
% compiles standalone.

% Find headers that include the one being cleaned.
hpp = header_search(header_being_cleaned,'hpp');
% In each header we find, include the one we removed.
for i=1:numel(hpp)
    h = hpp{i};
    try
        if ~insert_header(h,header_being_removed,[],header_being_cleaned)
            fprintf('Already present in %s\n',h);
        end
    catch E
        warning('mwood:tools:push_back_headers',E.message);
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
