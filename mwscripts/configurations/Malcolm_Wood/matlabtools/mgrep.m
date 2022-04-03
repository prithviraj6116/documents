function mgrep(str)

cmd = sprintf('find . -name "*.m" -exec grep -n -H %s {} \\;',str);
[status,out] = system(cmd);
if status~=0
    error('mwood:tools:mgrep','Failed to execute "grep": %s',out);
end
lines = mt_tokenize(out,newline);
matches = regexp(lines,'(?<file>[^:]*):(?<line>\d*):(?<text>.*)','names');
for i=1:numel(matches)
   m = matches{i}; 
   fprintf('<a href="matlab:opentoline(''%s'',%s)">%s:%s</a>  %s\n',...
       m.file,m.line,m.file,m.line,m.text);
end