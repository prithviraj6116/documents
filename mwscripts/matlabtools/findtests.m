function findtests(searchTerm)

% Construct Code Search URL
baseURL = 'http://codesearch.mathworks.com:8080/srcsearch/SearchResults.do?';
%searchTerm = 'slstarttest.FeaturedExampleProviderTest';
clusterToSearch = 'Bmain';
outputFileFormat = 'CSV';%'XML';
outputFileName = 'testList.txt';
outputFilePath = fullfile(pwd,outputFileName);
urlToSearch=['http://codesearch.mathworks.com/SearchResults.do?searchTerm=' searchTerm '&indexType=3&searchField=FILENAME&sort=FILETYPE&fileType=M&sourceDir=matlab%2Ftest&indexName=Bmain&indexDir=&f=' outputFileFormat];
urlToSearch1 = [...
    baseURL,...
    ['&indexName=',clusterToSearch],...
    ['&searchTerm=%22',searchTerm,'%22'],...
    '&caseSensitive=on',...
    '&searchField=TEXT',...
    '&sort=PATH',...
    '&fileType=M',...
    '&sourceDir=test/toolbox',...  % NOTE: assumed all tests will live under here
    '&indexId=3',...
    '&indexDir=',...
    ['&f=',outputFileFormat],...
    ];

% Read returned content
[searchStr,status] = urlread(urlToSearch);

if status == 1
    % Spilt string at line breaks
    searchStr = regexprep(searchStr,'"','');
    searchStr = regexp(searchStr,'\n','split');
    
    if isempty(searchStr{end})
        searchStr = searchStr(1:end-1);
    end
    
    % searchStr columns
    % 1)FileType, 2)matlabroot, 3)filePath, 4)FileName, 5)timeStamp
    
    try
        % Construct file path for each test
        fid = fopen(outputFilePath,'w+');
        
        for jj = 1:length(searchStr)
            
            fileInfo = strtrim(regexp(searchStr{jj},',','split'));
            filePath = regexprep([fileInfo{1,3},fileInfo{1,4}],'\','/');  % Unix filesep
            fprintf(fid,'%s\n',filePath);
            
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        rethrow(ME)
    end
    
else
    error('\nIssue with reading url: \n\n%s\n',urlToSearch);
end

fprintf('Wrote %s\n',outputFilePath);

% EOF