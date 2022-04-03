function mcov_generate_reports(matfiledirectory, outputdir, chartfile, buildnum)
% MCOV_GENERATE_REPORTS 
%
% mcov_generate_reports(matfiledirectory, outputdir, chartfile, buildnum)
% 
% mcov_generate_reports creates an html based viewer which shows
% the coverage of each directory in toolbox as exercised by the tests written
% specifically for that direcrory.
% 
% See also MCOV_HTML_TOOLBOX_REPORT, MCOV_HTML_MFILE_REPORT, MCOV_HTML_DIRECTORY_REPORT,
%          MCOV_DIRECTORYCOVERAGE.
% 

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:40 $

% capture the current time to start the clock.
starttime = clock;

if(nargin < 4)
    buildnum = getBuildNum;
end

% the structure which will contain the data for the whole of toolbox
totalcoverage.numberofmfiles = 0;
totalcoverage.totallinesofcode = 0;
totalcoverage.totalexecutablelines = 0;
totalcoverage.totalhitlines = 0;
totalcoverage.coverage = 0;
totalcoverage.directories = [];
totalcoverage.testdirectories = {};

% generate html display boolean switch
generatehtml = 1;

% directories we always want to skip in code coverage
skipdirectories = {'ja','obsolete'};

% make sure that the history directory exists
historydir = [];
if(exist(fullfile(outputdir, 'history')) ~= 7)
    % if it does not exist, make the history directory
    if(mkdir(outputdir, 'history'))
        historydir = fullfile(outputdir, 'history');
    else
        disp(sprintf('%s',...
            'Could not create or find history directory.  No history will be saved.'));
    end
else 
    historydir = fullfile(outputdir, 'history');
end

% get the source directories
if(iscell(chartfile))
    testdirectories = {};
    sourcedirectories = {};
    for counti = 1 : length(chartfile)
        % build a list of all source directories
        sourcedirectories = cat(2, sourcedirectories, chartfile{counti}(1));
        % build a list of all test directories
        % use union to prevent repeated directories
        testdirectories = union(testdirectories, chartfile{counti}{2});
    end
else
    sourcedirectories = getSourceDirectories;
    % get all the possible test directories
    testdirectories = getTestDirectories( chartfile, 'allSPIN');
end


% store the test directories into totalcoverage structure
totalcoverage.testdirectories = testdirectories;

% collect all the data desired for the reports
numberofsourcedirectories = length(sourcedirectories);
validdirectorycount = 0;
for counti = 1 : numberofsourcedirectories
    % to generate an html report for the source directories:
    % 1. get the test directories for the source directory
    % 2. determine which of those directories are relevent
    % 3. merge the mat files pertaining to the relevent test directories
    % 4. get the coverage data for the source directory based on the 
    %    coverage data just merged
    % 5. send the coverage data and generate html displays for that structue
    % 6. create an entry in the table for the current just generated
    % 7. sum the data with the data from the other entries
    
    % grab the current source directory
    isvaliddir = 1;
    if(iscell(chartfile))
        currentsourcedirectory = fullfile(matlabroot, sourcedirectories{counti});
        if(~exist(currentsourcedirectory))
            disp(sprintf('Source Directory \"%s\" does not exist.  Ignoring and continuing coverage',...
                currentsourcedirectory));
            isvaliddir = 0;
        else
            validdirectorycount = validdirectorycount + 1;
        end  
    else
        currentsourcedirectory = sourcedirectories{counti};
        validdirectorycount = validdirectorycount + 1;
    end
    
    if( isvaliddir )
        % for testing purposes print out source directory and
        disp(sprintf('Source Directory: %s', currentsourcedirectory));
        % start a timer to calculate the elapsed time to generate the coverage data
        % for this directory
        dirstarttime = clock;
        
        if( iscell(chartfile) )
            currenttestdirectories = chartfile{counti}{2};
        else
            [currenttestdirectories, exactmatch]= filterTestDirDependencies(testdirectories,...
                char(sourcedirectories(counti)));
            
            % if there was no exact match, limit the set of tests explored to those output
            % by TestsToRun for that specific directory
            if(~exactmatch)
                currenttestdirectories = getTestDirectories( chartfile, char(sourcedirectories{counti}) );
                currenttestdirectories = filterTestDirDependencies(currenttestdirectories,...
                    char(sourcedirectories{counti}));
            end
            
        end
        
        numberoftestdirectories = length(currenttestdirectories);
        
        % get all the names of the mat-files that we will be needing
        matfiles = {};
        for countj = 1 : numberoftestdirectories
            disp(sprintf('\ttest directory: %s', char(currenttestdirectories{countj})));
            if(~isempty(buildnum))
                newmatfile = getMCovMatFile(char(currenttestdirectories{countj}), matfiledirectory, buildnum);
            else
                newmatfile = getMCovMatFile(char(currenttestdirectories{countj}), matfiledirectory);
            end
            % check the output of getMCovMatFile and make sure that matfilename isn't empty
            % if it isn't empty, add it tothe rest of the matfiles
            if(~isempty(newmatfile))
                disp(sprintf('\tprofile data in: %s', char(newmatfile)));
                matfiles = cat(1, matfiles, newmatfile);
            else
                disp(sprintf('\tNo matfile found for the test directory'));
            end
        end
        
        % merge the profiles into a single data structure
        profiledata = [];
        if(~isempty(matfiles))
            profiledata = qemergeprofiles(matfiles);
        end
        
        % get the coverage data for the source directory
        sourcecoverdata = [];
        sourcecoverdata = mcov_directorycoverage(currentsourcedirectory, profiledata, skipdirectories);
        
        % save the coverage data to a mat file in the history directory
        if(~isempty(historydir))
            % tack on the date and the buildnumber to the structure
            sourcecoverdata.date = datestr(now, 'mm/dd/yy');
            sourcecoverdata.buildNum = buildnum;
            % save out the structure
            save(fullfile(historydir, makeCoverMatName(sourcecoverdata.name)), 'sourcecoverdata');
        end
        
        % sum the data with the total data
        totalcoverage.numberofmfiles = totalcoverage.numberofmfiles + ...
            sourcecoverdata.numMFiles;
        totalcoverage.totallinesofcode = totalcoverage.totallinesofcode + ...
            sourcecoverdata.numLinesOfCode;
        totalcoverage.totalexecutablelines = totalcoverage.totalexecutablelines + ...
            sourcecoverdata.numExecutableLines;
        totalcoverage.totalhitlines = totalcoverage.totalhitlines + ...
            sourcecoverdata.numCoveredLines;
        
        % generate html pages for this coverage data
        % continuously writing the file allows us to make sure that
        % we have data, even if the function errors out.
        if( generatehtml )
            coverURL = '';
	    % if there are test directories but no matfile
            % the tests must not have been run.  Therefore, do not
            % generate html for this coverage as it will overwrite
            % useful coverage data.
	    if( ~(isempty(matfiles) & ~isempty(currenttestdirectories)))
	        coverURL = mcov_html_directory_report(sourcecoverdata, outputdir);
            end
	    
            % if it is empty, initialize the array to an array of structures
            if(isempty(totalcoverage.directories))
	        totalcoverage.directories(validdirectorycount).name = '';
            end
            
            % add the current directory's data to totalcoverage 
            totalcoverage.directories(validdirectorycount).name = sourcecoverdata.name;
            totalcoverage.directories(validdirectorycount).numMFiles = sourcecoverdata.numMFiles;
            totalcoverage.directories(validdirectorycount).numCoveredLines = sourcecoverdata.numCoveredLines;
            totalcoverage.directories(validdirectorycount).numExecutableLines = sourcecoverdata.numExecutableLines;
            totalcoverage.directories(validdirectorycount).percentCov = sourcecoverdata.percentCov;
            totalcoverage.directories(validdirectorycount).URLtosummary = coverURL;
            totalcoverage.directories(validdirectorycount).testdirectories = currenttestdirectories;
            
            % write out the whole file
            mcov_html_toolbox_report(totalcoverage,...
                fullfile(outputdir, 'coveragesummary.html'),...
                fullfile(outputdir, 'mcov_testmapping.html'));
            
        end
        
        % stop the timer and disply the elapsed time
        dirstoptime = clock;
        disp(sprintf('time to generate coverage for %s: %f minutes',...
            char(sourcedirectories{counti}), etime(dirstoptime, dirstarttime)/60));
        
    end
end

% print out the total elapsed time
finishtime = clock;
disp(sprintf('total time for generation of code coverage: %f minutes',...
    etime(finishtime, starttime)/60));

return;

function z = getSourceDirectories()
% GETSOURCEDIRECTORIES returns a cell array of strings containing the source directories
%   which will have coverage data generated for them
%
% this implementation of the getSourceDirectories simply gets the 
% toolbox directories from the path and excludes some directories
% that we are sure we don't want test coverage for.
z = {};
pathstring = path;
directories = {};
skipdirectories = {...
        'local',...
        'xlate',...
    };
pathtotoolbox = fullfile(matlabroot, 'toolbox');


% path separators are different on PC than they are from UNIX
if(ispc)
    directories = stringtokens(pathstring,';');
elseif(isunix)
    directories = stringtokens(pathstring, ':');
end

% find where all the toolbox directories are
toolboxindices = strmatch(pathtotoolbox, directories);

% limit the set to the directories in toolbox
z = directories(toolboxindices);

% filter out any directories we don't want coverage for
numberofskipdirectories = length(skipdirectories);
for counti = 1 : numberofskipdirectories
    skipindices = strmatch(fullfile(pathtotoolbox, char(skipdirectories(counti))), z);
    if(~isempty(skipindices))
        z(skipindices) = [];
    end
end

% filter out any undesired directories containing keywords
z = filterKeywords(z);

return;

function z = getTestDirectories( chartfile, sourcedirectory )
% GETTESTDIRECTORIES returns a cell array containing the test directories that
% will be run when a change in sourcedirectory occurs

if(~isempty(sourcedirectory))
    % chop off matlab root from the source directory if it matches it
    sourcedirectory = strrep(sourcedirectory, [matlabroot filesep], '');
    % perl needs the fileseparators to be '/' and not '\' so flip them around
    sourcedirectory = strrep(sourcedirectory, filesep, '/');
end

% call TestsToRun to get the test directories run
% filter out any warnings
% take off any unnecessary newline characters
[returncode, data] = unix(sprintf('%s %s %s', 'TestsToRun', chartfile, sourcedirectory));

% look for an Error string in data
error = strmatch('TestsToRun ERROR:', data);
if(~isempty(error))
    error(data);
end

% break the data up by lines
z = stringtokens(data, sprintf('\n'));

% we know that the last lines is the only line we need to look at
data = char(z(end));

% break up the list of test directories by blank character
z = stringtokens(deblank(data), ' ');

return;

function [testdirectories, exactmatch] = ...
    filterTestDirDependencies(testdirectories, sourcedirectory)

% a list of directories we are sure we do not want
removedirectories = {...
        'test/checkin',...
        'test/qap'...
    };

% remove the directories listed in removedirectories
numberofremovedirectories = length(removedirectories);
for counti = 1 : numberofremovedirectories
    % removeindices = strmatch(char(removedirectories(counti)), testdirectories, 'exact');
    removeindices = strmatch(char(removedirectories(counti)), testdirectories);
    if(~isempty(removeindices))
        testdirectories(removeindices) = [];
    end
end

% remove any directories containing undesired keywords
testdirectories = filterKeywords(testdirectories);

% if the source directory is in toolbox then filter out all the tests that
% are not also in the same directory under toolbox: i.e. if source dir is
% toolbox/map/mapproj filter out all tests that are not under toolbox/map
if(findstr(sourcedirectory, 'toolbox'))
    dirtokens = stringtokens(sourcedirectory, filesep);
    numberoftokens = length(dirtokens);
    
    % first check the first directory under toolbox
    indices = strmatch('toolbox',dirtokens,'exact');
    if(~isempty(indices))
        testdir = 'test';
        findindices = [];
        % force the directories to be in the same directory
        % under toolbox 
        if(length(dirtokens) >= ( max(indices) + 1 ) )
            toolboxlocation = max(indices) + 1;
            toolboxdir = char(dirtokens(toolboxlocation));
            toolboxdir = fullfile(testdir, 'toolbox', toolboxdir);
            % perl returns the paths with '/' instead of '\'
            toolboxdir = strrep(toolboxdir, filesep, '/');
            findindices = strmatch(toolboxdir, testdirectories);
            if(~isempty(findindices))
                testdirectories = testdirectories(findindices);
            else
                testdirectories = [];
            end            
        end
        
        findindices = [];
        % see if there is an exact match
        toolboxdir = qetruncatepathfromdir(sourcedirectory,'toolbox');
        matchtestdir = fullfile(testdir, toolboxdir);
        findindices = strmatch(matchtestdir, testdirectories, 'exact');
        
        % look for sub directories
        matchtestdir = [fullfile(testdir, toolboxdir) filesep];
        subdirindices = strmatch(matchtestdir, testdirectories);
        
        if(~isempty(findindices) | ~isempty(subdirindices))
            testdirectories = testdirectories(union(findindices, subdirindices));
            if(nargout == 2)
                if(~isempty(findindices))
                    exactmatch = 1;
                else
                    exactmatch = 0;
                end
            end
        else
            % now look for the best match
            for counti = max(indices) : numberoftokens;
                topdir = char(dirtokens(counti));
                testdir = fullfile(testdir,topdir);
                % perl returns the paths with '/' instead of '\'
                testdir = strrep(testdir, filesep, '/');
                
                findindices = strmatch(testdir, testdirectories);
                if(~isempty(findindices))
                    testdirectories = testdirectories(findindices);
                else
                    break;
                end
            end
            
            % if the number of output arguments is 2 and the last directory searched
            % was a match for the test directory then we must indicate that there is
            % an exact match
            if(nargout == 2)
                if(counti == numberoftokens & ~isempty(findindices))
                    exactmatch = 1;
                else
                    exactmatch = 0;
                end
            end 
        end        
    end
end

return;

function z = filterKeywords( directories )

% a list of keywords we want to make sure we don't look at
keywords = {...
        'obsolete',...
        '/ja_',...
        [filesep 'ja_']...
    };

% filter out any directories with keywords in the name
for counti = length( directories ) : -1 : 1
    for countj = 1 : length(keywords)
        skipindices = findstr(char(directories(counti)), char(keywords(countj)));
        if(~isempty(skipindices))
            directories(counti) = [];
            break;
        end
    end
end

z = directories;

return;

function z = getMCovMatFile(test_directory_name,...
    mat_file_directory,...
    build_num...
    )
% builds up a file name for the mat file which most
% likely contains the profile data generated by tests
% in directory test_directory_name.  If the file doesn't
% exist, then getMCovMatFile will return an empty matrix 

% check the arguments
% if no test_directory_name is given
% or is 'none' is passed in
% return an empty matrix
if(nargin == 0 | isempty(test_directory_name) | strcmpi(test_directory_name, 'none'))
    z = [];
    return;
end

% if build_num wasn't specified use current build number
if(nargin < 2 | isempty(build_num))
    build_num = getBuildNum;
elseif(~ischar(build_num))
    build_num = num2str(build_num);
end

% build up the coverage file name
z = test_directory_name;
fileseps = find(z == '/');
z(1:fileseps(end-1))=[];
z=strrep(z,'/','_');
z = ['mcov_',build_num,'_',z,'_'];

% find the files that match
matfiles = dir(fullfile(mat_file_directory,[z '*.mat']));

% get the names out and put them into a cell array
z = {};
for counti = 1 : length(matfiles)
    z = cat(1, z, {fullfile(mat_file_directory, matfiles(counti).name)});
end 

return;

function z = getBuildNum()
% get the current build number so we can get the right MAT-files

verNum = version;
versionnum = strtok(verNum);
dotMarks = findstr(versionnum,'.');
z = versionnum(dotMarks(end)+1:end);

return;

function z = makeCoverMatName( dirname )
% creates a name for a mat-file which will be saved out
% to the history directory with the name mcov_dirname_MM_DD_YY.mat
dirname = qetruncatepathfromdir( dirname, 'toolbox' );
dirtokens = stringtokens(dirname,filesep);
dirname = qetruncatepathfromdir( dirname, char(dirtokens(2)) );

z = sprintf('mcov_%s_%s.mat',...
    strrep(dirname, filesep, '_'),...
    strrep(datestr(now, 'mm/dd/yy'),'/','_'));

return;

%%%%%%%%%%%%%%%%%%%%%% Basic Utility functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function z = stringtokens(tokenizethis, withthis)
% returns a cell array of strings, tokenized by withthis
z = {};

while(1)
    [T, tokenizethis] = strtok(tokenizethis, withthis);
    if(~isempty(T))
        z = cat(1, z, {T});
    else
        break;
    end
end

return;