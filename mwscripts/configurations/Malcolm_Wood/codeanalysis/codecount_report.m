function codecount_report(module,reportname)
% codecount_report - Generates a report of how line counts have changed over time
%
%  codecount_report(module,reportname)

startdir = pwd;
restoredir = onCleanup(@() cd(startdir));

jaroot = '/mathworks/devel/jobarchive/Aslrtw';
relroot = '/mathworks/UK/devel/archive';
ja = dir(jaroot);
rel = dir(relroot);

f = fopen(reportname,'w');
fprintf(f,'<?xml version="1.0"?>\n<codecount folder="%s">\n',module);
fclose(f);

lastdateval = 0;
for i=1:numel(ja)
    name = ja(i).name;
    if strcmp(name,'.') || strcmp(name,'..')
        continue;
    end
    if numel(name)<10
        continue;
    end
    date = name(1:10);
    date = strrep(date,'_',':');
    try
        dateval = datenum(date,'yyyy:mm:dd');
    catch E
        fprintf('Skipping %s\n',name);
        continue;
    end
    if dateval-lastdateval<=1
        % Ignore jobs accepted on the same day or consecutive days
        fprintf('Skipping %s\n',name);
        continue;
    end
    lastdateval = dateval;
    try
        cd(fullfile(jaroot,name,'matlab',module));
        [executable_count,comments,blanks,files] = executablelinecount('.');
        i_write(reportname,date,executable_count,comments,blanks,files);
    catch E
        fprintf('Failed for Aslrtw job archive %s: %s\n',name,E.message);
    end
end

for i=1:numel(rel)
    name = rel(i).name;
    if strcmp(name,'.') || strcmp(name,'..')
        continue;
    end
    if numel(name)~=6
        % Ignore releases which are not in the standard format
        fprintf('Skipping %s\n',name);
        continue;
    end
    date = name(2:5); % the year
    if name(6)=='a'
        date = [date ':01:01']; %#ok<AGROW> % count as 1st January
    elseif name(6)=='b'
        date = [date ':07:01']; %#ok<AGROW> % count as 1st July
    else
        fprintf('Skipping %s\n',name);
        continue;        
    end
    try
        cd(fullfile(relroot,name,'perfect','matlab',module));
        [executable_count,comments,blanks,files] = executablelinecount('.');
        i_write(reportname,date,executable_count,comments,blanks,files);
    catch E
        fprintf('Failed for release %s: %s\n',name,E.message);
    end
end

f = fopen(reportname,'a');
fprintf(f,'</codecount>\n');
fclose(f);

end


function i_write(report,date,ex,com,b,f)
fprintf('%s: %d executable lines, %d comments, %d files\n',date,ex,com,f);
f = fopen(report,'a');
fprintf(f,'<snapshot date="%s" executable="%d" comments="%d" blanks="%d" files="%d"/>\n',date,ex,com,b,f);
fclose(f);
end
