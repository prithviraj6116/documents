function files = cppgrep_m(str,ext)
% cppgrep - Search .cpp files in the current folder and its subfolders
%
% Returns a list of files which contain the supplied regular expression.

if nargin<2 || isempty(ext)
    ext = 'cpp';
end

[status,out] = system(['find -name "*.' ext '"']);
if status==1
    error('mwood:tools:cppgrep','%s',out);
end

files = strsplit(out,newline)';
files = files(~cellfun('isempty',files));

% Adjust expression so that it ignores double spaces, newlines, etc.
str = strrep(str,' ','\s*');

for i=1:numel(files)
    try
        files{i} = i_grep(files{i},str);
    catch E
        disp(E.message);
        files{i} = [];
    end
end

files = files(~cellfun('isempty',files));

end

function f = i_grep(f,str)
%disp(f);
t = mt_readtextfile(f,true); % single string
match = ~isempty(regexp(t,str,'once'));
if ~match
    f = [];
end
end