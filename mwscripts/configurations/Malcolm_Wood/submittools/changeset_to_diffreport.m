function changeset_to_diffreport(changenum,reportfile)
%changeset_to_diffreport - Generates an HTML report showing the changes in a sandbox
%
%  changeset_to_diffreport(changeset,reportfile)
%
% Both inputs are optional.  If no changeset is specified, the default
% changeset will be used.  If no reportfile is specified, a name will
% be generated.
%
% e.g. changeset_to_diffreport
%      changeset_to_diffreport(12345,'diffs.html')

if ~strcmp(pwd,sbroot)
    %error('mwood:tools:changeset','Not in sbroot');
    startdir = cd(sbroot);
    restoredir = onCleanup(@() cd(startdir));
end

if nargin==0
    changenum = 'default';
end
[files,actions] = get_changeset(changenum);
if isempty(files)
    html = sprintf('<p>No files specified in changeset</p>');
    index = {};
else
    fprintf('%d files in changeset\n',numel(files));
    html = cell(size(files));
    index = cell(size(files));
    added = zeros(size(files));
    deleted = zeros(size(files));
    for i=1:numel(files)
        thisfile = files{i};
        if actions(i)>=0
            % Not deleting.  File must be here.
            if ~exist(thisfile,'file')
                %decodefile = urldecode(thisfile);
                decodefile = strrep(thisfile,'%40','@');
                if ~exist(decodefile,'file')
                    warning('mwood:tools:diffreport','File not found: %s',thisfile);
                end
                thisfile = decodefile;
            end
        end
        anchor = matlab.lang.makeValidName(thisfile);
        open_hlink = sprintf('(<a href="matlab:edit ''%s''">open</a>) %s',thisfile, emacs_hyperlink(thisfile));
        if actions(i)==1
            nl = linecount(thisfile);
            index{i} = sprintf('<li><a href="#%s">%s</a> (added: +%d)',...
                anchor,thisfile,nl);
            added(i) = nl;
            deleted(i) = 0;
            html{i} = sprintf('<h3><a name="%s">%s %s</h3>\n<p>New (%d lines)</p>\n',anchor,thisfile,open_hlink,nl);
        elseif actions(i)==-1
            nl = linecount(getjobarchive(thisfile));
            anchor = matlab.lang.makeValidName(thisfile);
            index{i} = sprintf('<li><a href="#%s">%s</a> (deleted: -%d)',...
                anchor,thisfile,nl);
            added(i) = 0;
            deleted(i) = nl;
            html{i} = sprintf('<h3><a name="%s">%s</h3>\n<p>Deleted (%d lines)</p>\n',anchor,thisfile,nl);
        elseif actions(i)==-2
                % If this is a move/delete then don't count it, because
                % both added and deleted lines are counted for the
                % corresponding addition.
            anchor = matlab.lang.makeValidName(thisfile);
            index{i} = sprintf('<li><a href="#%s">%s</a> (moved)',...
                anchor,thisfile);
            added(i) = 0;
            deleted(i) = 0;
            html{i} = sprintf('<h3><a name="%s">%s</h3>\n<p>Moved</p>\n',anchor,thisfile);
        elseif actions(i)==0 || actions(i)==2 % edit or move/add
            command = sprintf('p4 diff %s',files{i});
            [status,output] = system(command);
            [html{i},index{i},added(i),deleted(i)] = diff_to_html(thisfile,anchor,open_hlink,output,~status);
        end
    end
    html{end+1} = sprintf('<p>Added %d lines.  Deleted %d lines</p>',sum(added),sum(deleted));
    fprintf('Added %d lines.  Deleted %d lines\n',sum(added),sum(deleted));
end
if nargin<2 || isempty(reportfile)
    reportfile = fullfile(pwd,['diffreport_' datestr(now,'yy_mm_dd:HH_MM') '.html']);
end
reportfile = mtfilename(reportfile);

% Write the whole file header
header = [...
    {sprintf('<html><head><title>Diff Report</title></head>')};...
    {'<body><ul>'};...
    index(:);
    {'</ul>'}];
% Assemble the full content and write it
html = [ header ; html(:) ; {'</body></html>'} ];
writetextfile(reportfile,html);
fprintf('Report written to %s\n',getabs(reportfile));
web(getabs(reportfile));
end
