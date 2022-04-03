function sbperdiff(filename,format)
%sbperdiff(filename,format)

if nargin<1 || isempty(filename)
    filename = editordoc;
end

absname = getabs(mtfilename(filename));
if ~exist(absname,'file')
    error('File not found: %s',absname);
end
sbr = sbroot(fileparts(absname));
relpath = absname(numel(sbr)+2:end); % sbr has no trailing slash
f = fopen(fullfile(sbr,'.last_sunc'));
if f==-1
    error('.last_sunc not found');
end
closefile = onCleanup(@() fclose(f));
perfect_root = fgetl(f);
if ~exist(perfect_root,'dir')
    error('Perfect area not found: %s',perfect_root);
end
perfect_file = fullfile(perfect_root,relpath);
if ispc && perfect_file(1)==filesep && perfect_file(2)~=filesep
    perfect_file = [filesep perfect_file];
end
if nargin>1
    visdiff(perfect_file,filename,format);
else
    visdiff(perfect_file,filename);
end
