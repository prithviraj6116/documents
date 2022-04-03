function [count,files] = find_including_sources(header)
% Counts and lists the source files which include the specified header,
% directly or indirectly

cmd = sprintf('find . -name "*.cpp_i" -exec grep -lcH %s {} \\;',header);
[success,output] = system(cmd);
if success
    error('Malcolm:findsources:grep_failure','%s',output);
end
lines = mt_tokenize(output);
count = numel(lines);
if nargout>1
    files = lines;
    for i=1:numel(lines)
        files{i} = regexprep(files{i},'_headerlist_unclassified.*','');
    end
end