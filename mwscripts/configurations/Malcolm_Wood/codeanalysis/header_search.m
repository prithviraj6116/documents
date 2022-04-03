function matches = header_search(header,ext,quiet)
% Finds files which include a given header, using the online codesearch.
%
% matches = header_search(header);
% matches = header_search(header,ext); % cpp or hpp
% matches = header_search(header,ext,quiet); % suppress command-window output
%
% This search matches the *full string* give for the header, so for an
% exported header used outside the model it is necessary to include the
% module prefix (e.g. simstruct/simstruc.h).  This will *not* find
% non-standard usages inside the module (e.g.
% export/include/simstruct/simstruc.g).

if nargin<3
    quiet = false;
end

if nargin<2 || isempty(ext)
    cpp_matches = header_search(header,'cpp',quiet);
    hpp_matches = header_search(header,'hpp',quiet);
    matches = [cpp_matches ; hpp_matches];
    
    if ~quiet && ~nargout
        clear matches
    end
    return;
end

searchTerm = strrep(header,'/',' ');
searchTerm = ['include ' searchTerm ''];
searchTerm = strrep(searchTerm,' ','%20');

clusterToSearch = 'Bslengine_integ';

% Construct Code Search URL
baseURL = 'http://codesearch.mathworks.com:8080/srcsearch/SearchResults.do?';
outputFileFormat = 'CSV';%'XML';

if strcmp(ext,'hpp')
    fileTypes = '&fileType=C%2FC%2B%2B+Header';
elseif strcmp(ext,'cpp')
    fileTypes = '&fileType=C&fileType=C%2B%2B';
else
    error('mwood:header_search:extension','Unexpected extension: %s',ext);
end

sourceDirs = ['&sourceDir=src&sourceDir=simulink%2Fsrc'...
    '&sourceDir=test&sourceDir=toolbox'];

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

if ~isempty(strfind(output,'DOCTYPE html'))
    % The server returns an HTML page if no matches are found.
    fprintf('No matches found for "%s"\n',searchTerm);
    matches = {};
    return;
end

% Spilt string at line breaks
output = strsplit(output,char(10));

if ~quiet
    % Filenames are given relative to matlabroot.  We'll need an absolute
    % path for the hyperlinks.
    r = sbroot;
    r = fullfile(r,'matlab');
end

% Columns are:
% 1)FileType, 2)matlabroot, 3)filePath, 4)FileName, 5)timeStamp
tokens = regexp(output,',','split');
matches = {};
for i=1:numel(tokens)
    columns = tokens{i};
    if numel(columns)<4
        continue;
    end
    dir = strtrim(columns{3});
    dir = dir(2:end-1); % strip quotes
    filename = strtrim(columns{4});
    filename = filename(2:end-1); % strip quotes
    matches{end+1} = [dir filename]; %#ok<AGROW>
    if ~quiet
        fprintf('%s<a href="matlab:edit %s/%s%s">%s</a>\n',dir,r,dir,filename,filename);
    end
end
if ~quiet
    fprintf('%d %s matches found (<a href="%s">Open in Browser</a>)\n',numel(tokens),upper(ext),urlToSearch);
end

matches = matches(:);
matches = strcat('matlab/',matches); % return relative to sbroot

if ~quiet && ~nargout
    clear matches
end

end
