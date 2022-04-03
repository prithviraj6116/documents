function submitfile_to_diffreport(submitfile,reportfile)
%submitfile_to_diffreport - Generates an HTML report showing the changes in a sandbox
%
%  submitfile_to_diffreport(submitfile,reportfile)
%
% job is either a file name or a job number in the form jobnumber@cluster
% reportfile is optional.  If omitted, a temp file will be used.
%
% e.g. submitfile_to_diffreport 1234@Aslww

files = parse_submitfile(submitfile);
if isempty(files)
    html = sprintf('<p>No files specified in %s</p>',submitfile);
    index = {};
else
    html = cell(size(files));
    index = cell(size(files));
    added = zeros(size(files));
    deleted = zeros(size(files));
    for i=1:numel(files)
        command = sprintf('mdiff %s',files{i});
        [success,output] = system(command);
        [html{i},index{i},added(i),deleted(i)] = diff_to_html(files{i},output,success);
    end
    html{end+1} = sprintf('<p>Added %d lines.  Deleted %d lines</p>',sum(added),sum(deleted));
    fprintf('Added %d lines.  Deleted %d lines\n',sum(added),sum(deleted));
end
if nargin<2 || isempty(reportfile)
    [~,sn] = fileparts(submitfile);
    reportfile = fullfile(pwd,['diffreport_' sn datestr(now,'yy_mm_dd:HH_MM') '.html']);
end
reportfile = mtfilename(reportfile);

% Write the whole file header
header = [...
    {sprintf('<html><head><title>Diff Report: %s</title></head>',submitfile)};...
    {'<body><ul>'};...
    index(:);
    {'</ul>'}];
% Assemble the full content and write it
html = [ header ; html(:) ; {'</body></html>'} ];
writetextfile(reportfile,html);
fprintf('Report written to %s\n',getabs(reportfile));
web(getabs(reportfile));
end
