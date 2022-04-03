function files = find_in_jobarchives(cluster,relpath)

files = {};
jaroot = ['/mathworks/devel/jobarchive/' cluster];
d = dir([jaroot '/201*']);
for i=1:numel(d)
    jafile = fullfile(jaroot,d(i).name,relpath);
    if exist(jafile,'file')
        files{end+1} = jafile; %#ok<AGROW>
        fprintf('<a href="matlab:edit %s">Found in %s</a>\n',jafile,d(i).name);
    else
        fprintf('Not found in %s\n',d(i).name);
    end
end
files = files(:);

end