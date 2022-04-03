function gensuites(folder)

if nargin<1
    folder = pwd;
end

d = sbroot;
f = fullfile(d,'suites.txt');

r = [fullfile(d,'matlab') '/'];

d = dir(fullfile(folder,'*.m'));

lines = cell(size(d));
for i=1:numel(d)
    thisfile = fullfile(folder,d(i).name);
    if strncmp(thisfile,r,numel(r))
        thisfile = thisfile(numel(r)+1:end);
    end
    lines{i} = ['-runsuite ' thisfile];
end

writetextfile(mtfilename(f),lines);

end