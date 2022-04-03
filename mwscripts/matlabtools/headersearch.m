function files = headersearch(searchTerm,clusterToSearch,silent)

if nargin<2
    clusterToSearch = 'Bstateflow';
end

if nargin<3
    silent = false;
end

% Construct Code Search URL
baseURL = 'http://codesearch.mathworks.com:8080/srcsearch/SearchResults.do?';
outputFileFormat = 'CSV';%'XML';

fileTypes = '&fileType=C%2FC%2B%2B+Header';

sourceDirs = ['&sourceDir=src&sourceDir=simulink%2Fsrc'...
    '&sourceDir=test&sourceDir=toolbox&sourceDir=standalone'...
    '&sourceDir=extern%252Finclude&sourceDir=packaging_libraries'...
    '&sourceDir=resources&sourceDir=rtw&sourceDir=stateflow&sourceDir=config'...
    '&sourceDir=foundation_libraries'];

urlToSearch = [...
    baseURL,...
    '&indexName=',clusterToSearch,...
    '&searchTerm=%22',searchTerm,'%22',...
    '&searchField=TEXT',...
    '&sort=PATH',...
    fileTypes,...
    sourceDirs];

% Read returned content
output = urlread([urlToSearch '&f=' outputFileFormat]);

if ~isempty(strfind(output,'DOCTYPE html'))
    % The server returns an HTML page if no matches are found.
    fprintf('No matches found for "%s"\n',searchTerm);
    files = {};
    return;
end

% Spilt string at line breaks
output = strsplit(output,char(10));

% Filenames are given relative to matlabroot.  We'll need an absolute
% path for the hyperlinks.
try
    r = sbroot;
    r = [r,'/matlab/'];
catch E
    r = [matlabroot '/'];
end

% Columns are:
% 1)FileType, 2)matlabroot, 3)filePath, 4)FileName, 5)timeStamp
tokens = regexp(output,',','split');

if nargout
    files = {};
end

for i=1:numel(tokens)
    columns = tokens{i};
    if numel(columns)<4
        continue;
    end
    dir = strtrim(columns{3});
    dir = dir(2:end-1); % strip quotes
    filename = strtrim(columns{4});
    filename = filename(2:end-1); % strip quotes
    if ~silent
        fprintf('%s<a href="matlab:edit %s%s%s">%s</a>\n',dir,r,dir,filename,filename);
    end
    if nargout
        files{end+1} = fullfile(dir,filename); %#ok<AGROW>
    end
end
if ~silent
    fprintf('%d matches found (<a href="%s">Open in Browser</a>)\n',numel(tokens),urlToSearch);
end

if nargout
    files = files(:);
end

end

