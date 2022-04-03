function files = cppgrep(str,ext)
% cppgrep - Search .cpp files in the current folder and its subfolders
%
% Returns a list of files which contain the supplied regular expression.

if nargin<2 || isempty(ext)
    ext = 'cpp';
end

[status,out] = system(['find -name "*.' ext '" | xargs grep -l "' str '"']);
if status==1
    error('mwood:tools:hppgrep','%s',out);
end

files = strsplit(out,newline)';

for i=1:numel(files)
    files{i} = files{i}(3:end); % strip "./"
end

files = files(~cellfun('isempty',files));

end