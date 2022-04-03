function appendtext(mf,t)
%MTFILENAME/APPENDTEXT Appends text to the file, creating it if necessary
%
% appendtext(mf,t)
%
% t can be a string or a cell array of strings.  If it is
% a cell array, the entries are written on separate lines.

f = fopen(mf,'at',true); % error on failure

if iscell(t)
    for i=1:numel(t)
        fprintf(f,'%s\n',t{i});
    end
else
    fwrite(f,t);
end

fclose(f);
