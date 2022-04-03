function files = get_changeset_files(num)
% Returns the list of files in the specified changeset
%
% files = get_changeset_files(num)

if ~ischar(num)
    num = sprintf('%d',num);
end

files = {};

output = p4command('describe -s %s',num);
if ~isempty(strfind(output,'no such changelist'))
    output = p4command('opened -c %s',num);
    output = strsplit(output,char(10));
    match = regexp(output,'\/\/mw\/[^\/]*\/(?<file>.*)\#.*','names');
else
    output = strsplit(output,char(10));
    match = regexp(output,'\.\.\. \/\/mw\/[^\/]*\/(?<file>.*)\#.*','names');
end
for k=1:numel(match)
    if ~isempty(match{k})
        files{end+1} = match{k}.file; %#ok<AGROW>
    end
end

files = sort(files(:));