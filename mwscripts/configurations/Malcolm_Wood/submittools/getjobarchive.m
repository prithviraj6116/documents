function r = getjobarchive(filename)
% getjobarchive - returns the sync location for the current sandbox
%
% r = getjobarchive
% f = getjobarchive(f) % returns location of file "f" in jobarchive

if nargin<1 || isempty(filename)
    r = i_jobarchive_root(sbroot);
else
    absname = getabs(mtfilename(filename));
    sbr = sbroot(fileparts(absname));
    relpath = absname(numel(sbr)+2:end); % sbr has no trailing slash
    r = i_jobarchive_root(sbr);
    r = slfullfile(r,relpath);
end
end

function jobarchive_root = i_jobarchive_root(sbr)
    f = fopen(fullfile(sbr,'.last_sunc'));
    if f==-1
        error('.last_sunc not found');
    end
    closefile = onCleanup(@() fclose(f));
    jobarchive_root = fgetl(f);
    if ~exist(jobarchive_root,'dir')
        error('jobarchivenot found: %s',jobarchive_root);
    end
end