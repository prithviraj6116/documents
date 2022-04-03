function writetextfile(mf,c)
%MTFILENAME/WRITETEXTFILE Writes a cell array of strings to a text file
%
% writetextfile(mf,c)
%
% If the file cannot be opened for writing an error will be thrown.
% If the cell array contains items other than strings, an error will be
% thrown.

assert(numel(mf)==1,'Exactly one file required');

c = mt_ensurecell(c);

for i=1:length(c)
    if ~ischar(c{i})
        error('mwood:tools:error','Entry %d in the array is not a string',i);
    end
end

hf = fopen(mf,'wt',true); % error on failure

fprintf(hf,'%s\n',c{:});

fclose(hf);
