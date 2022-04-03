function dirs = mt_subdirlist(startdir,print)

    if ~exist(startdir,'dir')
        error('mwood:tools:subdirlist','Folder not found: %s\n',startdir);
    end
    d = dir(startdir);
    d = d([d.isdir]);
    d = d(~strcmp({d.name},'.'));
    d = d(~strcmp({d.name},'..'));
    dirs = strcat(startdir,'/',{d.name}');
    subdirs = cell(size(dirs));
    for i=1:numel(dirs)
        subdirs{i} = mt_subdirlist(dirs{i});
    end
    dirs = vertcat(dirs,subdirs{:});
    
    if nargin>1 && print
        fprintf('%s\n',dirs{:});
    end
end