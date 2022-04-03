function t = mt_readtextfile(f,single_string)
% Returns the contents of a text file
%
% t = mt_readtextfile(f,single_string)
%
% f is a file name
% If single_string is supplied and true, the text is returned as a string.
% Otherwise it is returns as a cell array of strings: one element per line.
%
% This is a standalone function.  It is similar to calling:
%  t = readtextfile(mtfilename(f));
% but is independent of the mtfilename class, and other functions in this
% folder, for portability.

assert(ischar(f),'File name must be a string');

hf = fopen(f,'rt');
if hf<0
    error('mwood:tools:fopen','Failed to open %s for reading',f);
end
closefile = onCleanup(@() fclose(hf));

if nargin>1 && single_string
    t = fread(hf,'*char')';
    assert(feof(hf)==1,'Failed to read to the end of the file');
else
    % Can't use textscan here because it discards leading whitespace
    %c = textscan(hf,'%s','delimiter',char(10),'whitespace','');
    %c = c{1};
    t = cell(1000,1);
    count = 1;
    while 1
        ln = fgetl(hf);
        if ~ischar(ln)
            break;
        else
            t{count} = ln;
            count = count + 1;
        end
    end
    if count<1000
        t = t(1:count-1);
    end
end

end
