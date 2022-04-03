function sbedits(folder,outfile)

if nargin<1 || isempty(folder)
    folder = pwd;
end

if nargin<2 || isempty(outfile)
    outfile = fullfile(pwd,'submit.txt');
end

sbroot(folder); % just to check we're in a valid sandbox

fh = fopen(outfile,'w');
closefile = onCleanup(@() fclose(fh));
i_run(folder,fh);

end


function i_run(folder,fh)

d = dir(folder);
olddir = cd(folder);
restore_dir = onCleanup(@() cd(olddir));

r = sbroot;
for i=1:numel(d)
    name = d(i).name;
    fullname = fullfile(folder,name);
    fullname = fullname(numel(r)+2:end);

    if strcmp(name,'.')
        continue;
    elseif strcmp(name,'..')
        continue;
    elseif name(end)=='~'
        continue;
    elseif d(i).isdir
        i_run(fullfile(folder,d(i).name),fh);
    else
        [status,out] = system(['sbperdiff ' name]);
        switch status
            case 0
                fprintf('Not edited: %s\n',fullname);
            case 1
                fprintf('Edited: %s\n',fullname);
                fprintf(fh,'%s\n',fullname);
            otherwise
                fprintf('Error: %s\n%s\n\n',fullname,out);
        end
    end
    drawnow;
end

end