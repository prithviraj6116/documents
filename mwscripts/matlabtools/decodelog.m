function decodelog(logfile,outfile)
% decodelog - Decodes C++ stack traces in a log

output = decodestack(logfile,true);
lines = mt_tokenize(output,char(10));

% The lines printed by NativeStack are of the form:
%   [ 22] 0x001234 my::function::name(argtype) at /path/filename.cpp:44 (in /path/lib.so)
% We want the function name, the file name and line, and the library name
% for each line of output.
matches = regexp(lines,'(?<num>\[ *\d*\]) 0x[^ ]* (?<name>.*) at (?<file>.*) \((?<library>.*)\)','names');

for i=1:numel(matches)
    m = matches{i};
    if isempty(m)
        str = strtrim(lines{i}(10:end));
        if ~isempty(str)
            fprintf('%s\n',str);
        end
    else
        % Get the function name, stripping off any brackets
        function_name = m.name;
        frame_num = m.num;
        brackets = regexp(function_name,'[\(\<]');
        if ~isempty(brackets)
            if brackets(1)>1
                function_name = function_name(1:brackets(1)-1);
            end
        end
        
        if strcmp(function_name,'mcr::runtime::InterpreterThread::Impl::invocation_request_handler')
            % Nothing after this is of interest.  It indicates that the
            % function was called from the MATLAB prompt.
            fprintf('Called from MATLAB command-line\n');
            break;
        end
        
        % Get the library name
        if strncmp(m.library,'in ',3)
            m.library(1:3) = [];
        end
        [~,library_name,library_extension] = fileparts(m.library);
        library_name = [library_name library_extension]; %#ok<AGROW>
        
        % Find a colon in the filename: the number after the colon is
        % the line number.
        colon = find(m.file==':');
        if ~isempty(colon)
            filenameonly = m.file(1:colon(end)-1);
            line_number = m.file(colon(end)+1:end);
        else
            filenameonly = m.file;
            line_number = '1';
        end
        [~,shortfilename,shortfileext] = fileparts(m.file);
        shortfilename = [shortfilename shortfileext]; %#ok<AGROW>
        % Print this stack trace entry in the command window, including
        % a hyperlink to open the source code in the MATLAB Editor.
        if strcmp(library_name,'no debugging symbols found')
            fprintf('%s: %s (%s)\n',...
                frame_num,function_name,shortfilename);
        else
            fprintf('%s: %s (<a href="matlab:opentoline(''%s'',%s)">%s</a> in %s)\n',...
                frame_num,function_name,filenameonly,line_number,shortfilename,library_name);
        end
        
    end
end
