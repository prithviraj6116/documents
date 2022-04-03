function mf = mt_filesearch(startpath,recurse,ext)
% FILESEARCH Recursively finds files with a given extension.
%
%  Searches a specified path (recursively or non-recursively) for files with
%  a given extension.
%  Results are returned as an mtfilename array.
%
% files = mt_filesearch(startpath,recurse,ext)
%
% "ext" includes the dot.
%

if nargin<2
    recurse = 0;
end

mfStartPath = mtfilename(startpath);
mf = mtfilename(0);

if recurse
	%Create string of recursive directories/subdirectories
	paths = genpath(getabs(mfStartPath));
    paths = mt_tokenize(paths,pathsep);
    mfPaths = mtfilename(paths);
    for i=1:numel(mfPaths)
        mfTemp = i_rundir(mfPaths(i),ext,recurse);
        mf = [mf ; mfTemp]; %#ok<AGROW>
    end
else %Search non-recursively
    mf = i_rundir(mfStartPath,ext,recurse);
end

%%%%%%%%%%%%%%
function mf = i_rundir(mfDir,ext,recurse)

w = dir(getabs(mfDir));
ind = logical([w.isdir]);
if recurse
    subdirs = { w(ind).name };
    match = regexp(subdirs,'^@');
    isclassdir = ~cellfun('isempty',match);
    methods = mtfilename;
    for i = find(isclassdir)
        classname = subdirs{i};
        methods = [ methods ; i_rundir(mt_fullfile(mfDir,classname),'.m',1) ]; %#ok<AGROW>
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

mf = [mf ; methods];





