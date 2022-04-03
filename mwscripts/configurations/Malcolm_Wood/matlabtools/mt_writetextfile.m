function mt_writetextfile(f,c)
% Writes a string or cell array of strings to a text file
%
% mt_writetextfile(f,c)
%
% If the file cannot be opened for writing an error will be thrown.
% If the cell array contains items other than strings, an error will be
% thrown.

assert(ischar(f),'File name must be a string');

hf = fopen(f,'wt');
if hf<0
    error('mwood:tools:fopen','Failed to open %s for writing',f);
end
closefile = onCleanup(@() fclose(hf));

if ischar(c)
    fprintf(hf,'%s',c);
elseif iscell(c)
    assert(all(cellfun(@ischar,c)),'All cells must contain strings');        
    fprintf(hf,'%s\n',c{:});
end
end