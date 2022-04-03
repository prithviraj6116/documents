function components = matlabCodeDependencies(folder,include_subfolders)
% Identifies components called by MATLAB code in the specified folder
%
% components = matlabCodeDependencies(folder,include_subfolders)
%
% All MATLAB files in the specified folder (and optionally its subfolders)
% are analyzed.  Text files are written, listing the files in the folder(s),
% the references to other files, and the components owning these referenced
% files.

if ~exist(folder,'dir')
    error('mwood:tools:FolderNotFound','Folder not found: %s',folder);
end

% References will be to files in the MATLAB installation, regardless of
% which folder we're actually analyzing.
sbr = matlabroot;
if sbr(end)~='/'
    sbr = [sbr '/'];
end
if ~strncmp(folder,sbr,numel(sbr))
    error('mwood:tools:FolderNotInSandbox',...
        'Folder not inside this matlab installation: %s',folder);
end
key = folder(numel(sbr)+1:end);
key = strrep(key,'/','_');
key = genvarname(key);

if nargin<2
    include_subfolders = true;
end
c = mt_filesearch(folder,include_subfolders,'.m');
fprintf('%d MATLAB files found in %s\n',numel(c),folder);

mca = dependencies.MCodeAnalyzer;

% If the folder's not on the path then we'll need to cd to it.
% startdir = pwd;
% restoredir = onCleanup(@() cd(startdir));
%     d = fileparts(c{i});
%     cd(d);
%     mca.AnalyzeFile(c{i});

filenames = getabsx(c);
for i=1:numel(c)
    mca.AnalyzeFile(filenames{i});
end

r = mca.getAllReferences;
fprintf('%d references to external files found\n', numel(r));
out = evalc('disp(r)');
writetextfile(mtfilename([key '_references.txt']),out);
clear out; % because it could be large

extrefs = {};
for i=1:numel(r)
    f = r(i).FileName;
    if ~strncmp(f,[folder '/'],numel(folder)+1)
        % Not in this folder
        if strncmp(f,sbr,numel(sbr))
            % Under matlabroot
            extrefs{end+1} = f(numel(sbr)+1:end); %#ok<AGROW>
        end
    end
end
numrefs = numel(extrefs);
extrefs = unique(extrefs);
fprintf('%d references to files inside matlabroot found (%d unique names)\n',...
    numrefs,numel(extrefs));

listfilename = [key '_filelist.txt'];

listfile = mtfilename(listfilename);
writetextfile(listfile,extrefs);

[status,out] = system(['getScmComponentOwner -file_list ' listfilename]);
if status
    error('mwood:tools:getScmComponentOwner','Error: %s',out);
end

ownersfilename = [key '_components.txt'];
ownersfile = mtfilename(ownersfilename);
writetextfile(ownersfile,out);

lines = mt_tokenize(out,char(10));
matches = regexp(lines,'File: (?<filename>.*) is owned by component: (?<component>.*)','names');
components = {};
for i=1:numel(matches)
    m = matches{i};
    if ~isempty(m)
        components{end+1} = m.component; %#ok<AGROW>
    end
end
components = unique(components);
fprintf('%d owner components identified \n',numel(components));

componentsfilename = [key '_components.txt'];
componentsfile = mtfilename(componentsfilename);
writetextfile(componentsfile,components);

