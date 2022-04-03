function header_inclusion_report(headers_folder,ext)
% header_inclusion_report(headers_folder,ext)

if nargin<1 || isempty(headers_folder)
    headers_folder = pwd;
end

if nargin<2 || isempty(ext)
    ext = '.hpp';
end

startdir = cd(headers_folder);
restoredir = onCleanup(@() cd(startdir));
headers = find_files_by_type(ext);
delete(restoredir);

include_count = zeros(size(headers));
line_count = zeros(size(headers));
weight = zeros(size(headers));

h = waitbar(0,'Finding inclusions...');
c = onCleanup(@() delete(h));
n = numel(headers);
for i=1:n
    waitbar(i/n,h,sprintf('Finding inclusions... (%d of %d)',i,n));
    f = headers{i};
    if f(1)=='.'
        f(1) = [];
    end
    f = fullfile(headers_folder,f);
    include_count(i) = includecount_database(f);
    line_count(i) = linecount_database(f);
    weight(i) = include_count(i)*line_count(i);
    fprintf('%s (%d lines) included by %d source files  (weight=%d)\n',...
        headers{i},line_count(i),include_count(i),weight(i));
end
[weight,order] = sort(weight,1,'descend');
headers = headers(order);
line_count = line_count(order);
include_count = include_count(order);

html = {};
html{end+1} = '<html><body>';
html{end+1} = '<h1>Header Include Count</h1>';
html{end+1} = sprintf('<p>Lists the number of source files in %s including each header file in %s.</p>',pwd,headers_folder);
html{end+1} = '<table border="1"><tr><th>Header</th><th>Include Count</th><th>Line Count</th><th>Weight</th></tr>';
for i=1:numel(headers)
    html{end+1} = sprintf('<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td></tr>',...
        headers{i}, include_count(i), line_count(i), weight(i)); %#ok<*AGROW>
end
html{end+1} = '</table></body></html>';

report = mtfilename('include_report.html');
writetextfile(report,html);
web(getabs(report));
    