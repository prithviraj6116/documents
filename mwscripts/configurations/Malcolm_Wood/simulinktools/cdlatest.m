function restoredir = cdlatest(area)

startdir = pwd;

if ispc
    dirname = ['\\mathworks\devel\jobarchive\' area '\latest_pass'];
else
    dirname = ['/mathworks/devel/jobarchive/' area '/latest_pass'];
end

if ispc
    ah_dirname = ['\\mathworks\AH\devel\jobarchive\' area '\latest_pass'];
else
    ah_dirname = ['/mathworks/AH/devel/jobarchive/' area '/latest_pass'];
end

if ispc
    archivename = ['\\mathworks\devel\archive\' area '\perfect'];
else
    archivename = ['/mathworks/devel/archive/' area '/perfect'];
end
    
if ~exist(dirname,'dir')
    if ~exist(archivename,'dir')
        if ~exist(ah_dirname,'dir')
            error('mwood:tools:notfound','Can''t find any suitable folder:\n  %s\n  %s\n  %s',...
                dirname,archivename, ah_dirname);
        else
            dirname = ah_dirname;
        end
    else
        dirname = archivename;
    end
end
cd(dirname);
fprintf('Initial cwd: <a href="matlab:cd %s">%s</a>\n',startdir,startdir);
fprintf('New cwd: <a href="matlab:cd %s">%s</a>\n',dirname,dirname);

if nargout
    restoredir = onCleanup(@() cd(startdir));
end

