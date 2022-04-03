function [executable_count,comments,blanks,files] = executablelinecount(filename,include_headers)
% Counts the number of executable lines of code in a file or folder
% 
% [executable_count,comments,blanks,files] = executablelinecount(filename)
%
% Uses the "cloc" tool to generate these numbers

txt = perl('/hub/share/sbtools/apps/mw-coverage/cloc-1.07.pl',filename,'--quiet','--progress-rate=0','--xml');
txt = strtrim(txt);

t = [tempname '_cloc.xml'];
f = fopen(t,'wt');
fprintf(f,'%s',txt);
fclose(f);

try
    dom = xmlread(t);
catch E %#ok<NASGU>
    delete(t);
    error(txt);
    return;
end

executable_count = 0;
comments = 0;
blanks = 0;
files = 0;

if nargin<2
    include_headers = true;
end

langnodes = dom.getElementsByTagName('language');
for i=1:langnodes.getLength
    node = langnodes.item(i-1);
    lang = char(node.getAttribute('name'));
    if strcmp(lang,'C++') || (include_headers && strcmp(lang,'C/C++ Header'))
        executable_count = executable_count + str2double(char(node.getAttribute('code')));
        comments = comments + str2double(char(node.getAttribute('comment')));
        blanks = blanks + str2double(char(node.getAttribute('blank')));
        files = files + str2double(char(node.getAttribute('files_count')));
    end
end

delete(t);

% Easier to use regexp than to deal with the DOM API.
%exp = '<total\s+sum_files="(?<files>\d+)"\s+blank="(?<blank>\d+)"\s+comment="(?<comment>\d+)"\s+code=\"(?<code>\d+)';
%s = regexp(txt,exp,'names');
%if isempty(s)
%    error('mwood:codeanalysis:cloc','Unexpected output from "cloc": %s',txt);
%end
%executable_count = str2double(s.code);
%comments = str2double(s.comment);
%blanks = str2double(s.blank);
%files = str2double(s.files);

end

