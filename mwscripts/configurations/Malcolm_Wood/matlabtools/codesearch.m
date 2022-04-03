function files = codesearch(searchTerm,clusterToSearch,silent)

if nargin<2 || isempty(clusterToSearch)
    clusterToSearch = 'Bslx';
end

if nargin<3
    silent = false;
end

% Construct Code Search URL
baseURL = 'http://codesearch.mathworks.com:8080/srcsearch/SearchResults.do?';
outputFileFormat = 'CSV';%'XML';

fileTypes = ['&fileType=M&fileType=Java&fileType=C%2B%2B&fileType=C%2FC%2B%2B+Header'...
    '&fileType=C&fileType=XML&fileType=Resource&fileType=TLC&fileType=Makefiles'...
    '&fileType=Module+Dependencies&fileType=MTF&fileType=Requirements&fileType=C%2523'...
    '&fileType=JavaScript&fileType=Chart'];
%fileTypes = '&fileType=C%2B%2B';

sourceDirs = ['&sourceDir=matlab%2Fjava&sourceDir=matlab%2Fsrc&sourceDir=matlab%2Fsimulink%2Fsrc'...
    '&sourceDir=matlab%2Ftest&sourceDir=matlab%2Ftoolbox&sourceDir=matlab%2Fstandalone'...
    '&sourceDir=matlab%2Fmakerules&sourceDir=extern%252Finclude&sourceDir=matlab%2Fpackaging_libraries'...
    '&sourceDir=matlab%2Fresources&sourceDir=matlab%2Frtw&sourceDir=matlab%2Fstateflow&sourceDir=matlab%2Fconfig'...
    '&sourceDir=matlab%2Ffoundation_libraries'];

urlToSearch = [...
    baseURL,...
    '&indexName=',clusterToSearch,...
    '&searchTerm=%22',searchTerm,'%22',...
    '&caseSensitive=on',...
    '&searchField=TEXT',...
    '&sort=PATH',...
    fileTypes,...
    sourceDirs];

% Read returned content
output = urlread([urlToSearch '&f=' outputFileFormat]);

if contains(output,'DOCTYPE html')
    % The server returns an HTML page if no matches are found.
    fprintf('No matches found for "%s"\n',searchTerm);
    files = {};
    return;
end

% Spilt string at line breaks
output = strsplit(output,newline);

% Filenames are given relative to matlabroot.  We'll need an absolute
% path for the hyperlinks.
try
    r = sbroot;
catch E
    r = slfileparts(matlabroot);
end

% Columns are:
% 1)FileType, 2)matlabroot, 3)filePath, 4)FileName, 5)timeStamp
tokens = regexp(output,',','split');

if nargout
    files = {};
end

match_count = numel(tokens);
for i=1:numel(tokens)
    columns = tokens{i};
    if numel(columns)<4
        match_count = match_count - 1;
        continue;
    end
    dir = strtrim(columns{3});
    dir = dir(2:end-1); % strip quotes
    filename = strtrim(columns{4});
    filename = filename(2:end-1); % strip quotes
    abspath = slfullfile(r,dir,filename);
    if ~silent
        editor_hlink = sprintf('<a href="matlab:edit %s">%s</a>',abspath,filename);
        emacs_hlink = emacs_hyperlink(abspath);
        fprintf('%s/%s %s\n',dir,editor_hlink,emacs_hlink);
    end
    if nargout
        files{end+1} = fullfile(dir,filename); %#ok<AGROW>
    end
end
if ~silent
    fprintf('%d matches found (<a href="%s">Open in Browser</a>)\n',match_count,urlToSearch);
end

if nargout
    files = files(:);
end

end

