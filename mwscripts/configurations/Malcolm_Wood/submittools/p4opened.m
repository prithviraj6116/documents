function files = p4opened(changenum)

if nargin && ~isempty(changenum)
    if ~ischar(changenum)
        changenum = num2str(changenum);
    end
    changenum = ['-c ' changenum];
else
    changenum = '...';
end

output = p4command(['opened ' changenum]);
t = strsplit(output,newline);
match = regexp(t,'\/\/mw\/[^\/]*\/(?<file>.*)\#.*','names');
match = [match{:}];
if isempty(match)
    match = regexp(t,'\/\/mwpdb\/[^\/]*\/[^\/]*\/[^\/]*\/(?<file>.*)\#.*','names');
    match = [match{:}];
end
match = {match.file}';
match = strrep(match,'%40','@');

for i=1:numel(match)
    [d,n,e] = fileparts(match{i});
    emacs_hlink = emacs_hyperlink(match{i});
    fprintf('   %s%s<a href="matlab:edit %s">%s%s</a> %s\n',d,filesep,match{i},n,e,emacs_hlink);
end

if nargout
    files = match;
end

end