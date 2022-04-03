function mf = mt_filesearch(startpath,recurse,ext)
%MT_FILESEARCH Finds files in a given folder an, optionally, its subfolders
%
%  Searches a specified path (recursively or non-recursively) for files with
%  a given extension.
%  Results are returned as an mtfilename array.
%
% files = mt_filesearch(startpath,recurse,ext)
%
% "ext" includes the dot.
%

if isunix && recurse
    % Much quicker to use "find" on Linux.
    cmd = sprintf('find %s -name \\*%s',startpath,ext);
    [~,output] = system(cmd);
    names = strsplit(output,char(10))';
    if isempty(names{end})
        names(end) = [];
    end
    mf = mtfilename(names);
    return;
end

mfStartPath = mtfilename(startpath);
mf = mtfilename(0);

if recurse
	files = {};
	%Create string of recursive directories/subdirectories
	paths = genpath(getabs(mfStartPath));
    paths = mt_tokenize(paths,pathsep);
    mfPaths = mtfilename(paths);
    for i=1:numel(mfPaths)
        mfTemp = i_rundir(mfPaths(i),ext,recurse);
        mf = [mf ; mfTemp];
    end
else %Search non-recursively
    mf = i_rundir(mfStartPath,ext,recurse);
end

%%%%%%%%%%%%%%
function mf = i_rundir(mfDir,ext,recurse)

w = dir(getabs(mfDir));
ind = logical([w.isdir]);
if recurse && (isempty(ext) || strcmp(ext,'.m'))
    subdirs = { w(ind).name };
    match = regexp(subdirs,'^@');
    isclassdir = ~cellfun('isempty',match);
    methods = mtfilename;
    for i = find(isclassdir)
        classname = subdirs{i};
        methods = [ methods ; i_rundir(fullfile(mfDir,classname),'.m',1) ];
    end
else
    methods = mtfilename;
end

w = w(~ind);
mf = mtfilename(numel(w));
for i=1:numel(mf)
    mf(i) = fullfile(mfDir,w(i).name);
end
mf = mf(matchext(mf,ext));

for i=1:numel(mf)
    fprintf('Found: %s\n',getabs(mf(i)));
end

mf = [mf ; methods];





