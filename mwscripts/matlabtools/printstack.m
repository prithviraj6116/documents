function printstack(s,show_hyperlinks,prune)
% printstack - Tidies up a supplied C++ stack trace

if ischar(s)
    lines = mt_tokenize(s,newline);
else
    lines = s;
end

if nargin<2
    show_hyperlinks = true;
end

% If we find a line containing "EvalCmdForDebugger" then assume that it
% indicates the call to our "nativestack" function itself, and remove
% everything before it.
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
matches = regexp(lines,'\[ *(?<frame>\d*)\] 0x[^ ]* (?<name>.*) at (?<file>[^\(]*) .*\((?<library>in .*)\)','names');

if all(cellfun('isempty',matches))
    % No matches.  Try the format used by "gdb" instead.
    matches = regexp(lines,'#(?<frame>\d*) 0x[^ ]* in (?<name>.*) \(.*\) at (?<file>[^\(]*)','names');
end

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
        if ~isfield(m,'library')
            m.library = '?';
        end
        
        % Get the library name
        if strncmp(m.library,'in ',3)
            m.library(1:3) = [];
        end
        [~,library_name,library_extension] = fileparts(m.library);
        library_name = [library_name library_extension]; %#ok<AGROW>
        
        if prune && skipNativeStackPrint(library_name, function_name,'')
            continue;
        end
        
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
        
        framenum = count;
        if isfield(m,'frame')
            framenum = str2double(m.frame);
            if isnan(framenum)
                framenum = count;
            end
        end
        % Print this stack trace entry in the command window, including
        % a hyperlink to open the source code in the MATLAB Editor.
        if strcmp(library_name,'no debugging symbols found')
            fprintf('%d: %s (%s)\n',...
                framenum,function_name,shortfilename);
        else
            if show_hyperlinks
                emacs_link = [' ' emacs_hyperlink(m.file)];
                filenameonly1 = [matlabroot filenameonly(8:end)];
                editor_link = sprintf('<a href="matlab:opentoline(''%s'',%s)">%s</a>',filenameonly1,line_number,shortfilename);
            else
                emacs_link = '';
                % Include two folder names with the filename
                [fd,fs,fe] = slfileparts(filenameonly);
                [fd,d1] = slfileparts(fd);
                [~,d2] = slfileparts(fd);
                editor_link = [ slfullfile(d2,d1,[fs fe]) ':' line_number ];
            end
            
            d1=sprintf('%d: %s (%s%s in %s)\n',...
                framenum,function_name,editor_link,emacs_link,library_name);
            disp(d1);
            %fprintf(2,d1);
        end
        
        count = count + 1;
    end
end
