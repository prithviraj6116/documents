function mt_stack

% Get the C++ stack trace and save it in a temporary file
s = slsvInternal('NativeStack');
tmpfile = [tempname '.txt'];
writetextfile(mtfilename(tmpfile),s);
deletefile = onCleanup(@() delete(tmpfile));

decoder = fullfile(matlabroot,'tools','share','stack_decoder.pl');

cmd = ['mw -using ' fileparts(matlabroot) ' perl ' decoder ' --in=' tmpfile];
[success,output] = system(cmd);
if success~=0
    disp(s);
    error('mwood:tools:stacktrace',...
        'Failed to decode stack trace: %s\n',output);
end

lines = mt_tokenize(output,char(10));

% Skip over lines until we find the first instance
% of EvalCmdForDebugger, which indicates the call to this
% function itself.
for i=1:numel(lines)
    if ~isempty(regexp(lines{i},'EvalCmdForDebugger','once'))
        lines = lines(i+1:end);
        break;
    end
end

% The lines printed by NativeStack are of the form:
%   [ 22] 0x001234 my::function::name(argtype) at /path/filename.cpp:44 (in /path/lib.so)
% We want the function name, the file name and line, and the library name
% for each line of output.
matches = regexp(lines,'\[ *\d*\] 0x[^ ]* (?<name>.*) at (?<file>.*) \(in (?<library>.*)\)','names');

count = 1;

for i=1:numel(matches)
    m = matches{i};
    if ~isempty(m)
        % Get the function name, stripping off any brackets
        function_name = m.name;
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
        fprintf('%d: %s (<a href="matlab:opentoline(''%s'',%s)">%s</a> in %s)\n',...
            count,function_name,filenameonly,line_number,shortfilename,library_name);
        
        count = count + 1;
    end
end
