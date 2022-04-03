function coverstruct = mcov_directorycoverage( directory, profileData, skipdirectories )
% coverstruct = mcov_directorycoverage(directory, profileData, skipdirectories)
% 
% mcov_directorycoverage is a recursive function which
% traverses down a directory tree, generating coverage
% data for each of the directories underneath it.
% 
% the structure of the data returned is a tree with each node of the tree having the
% the following structure:
% name        -- char array containing the directory name
% numMFiles      -- number of m-files in this directory
% numCoveredLines    -- total covered lines of code in this directory
% numExecutableLines -- total useful lines of code
% numLinesOfCode
% percentCov     -- total code coverage
% childDir       -- a cell array containing the data related to any child directories.
%                   empty if there are no directories in this directory
% mFiles         -- a cell array containing the profileData structures for any m-files
%                   in this directory
% 
% See also MCOV_PROFILE2COVERAGE.

%   $Revision: 1.2 $  $Date: 2004/10/18 14:10:05 $

% a list of directories to skip over
skipdir = {...
        '.',...
        '..'...
    };

% append the directories passed in to the skipdir list
if(nargin > 2)
    skipdir = cat(2, skipdir, skipdirectories);
end

% MW: pre-process file names for performance reasons
sizeFT = size(profileData.FunctionTable);
profileData.ProcessedFileNames = cell(sizeFT);
for t = 1:sizeFT(1) 
    profiledmfile = profileData.FunctionTable(t).FileName;
    %Clip all matlab root information from the mfile name
    %only if the m-file is under the 'toolbox' hierarchy.
    s = findstr(profiledmfile, 'toolbox');
    if ~isempty(s)
      profiledmfile = profiledmfile(s:end);
    end
    % force everthing to lower case.
    profiledmfile = lower(profiledmfile);
    % make all directories unix style
    profiledmfile = strrep(profiledmfile, '\', '/');
    profileData.ProcessedFileNames{t} = profiledmfile;
end

% store the current directory to allow a return to it
previousdirectory = pwd;
    
disp(sprintf('Generating coverage data for the directory %s', directory));

% cd to the directory to be covered
cd(directory);

% get the string with the full path to the working directory
currentdirectory = pwd;

% return to the previous directory
cd(previousdirectory);

% initialize the data structure
coverstruct.name = currentdirectory;
coverstruct.numMFiles = 0;
coverstruct.numHitFiles = 0;
coverstruct.numCoveredLines = 0;
coverstruct.numExecutableLines = 0;
coverstruct.numLinesOfCode = 0;
coverstruct.percentCov = 0;
% these structures will be created later
coverstruct.childDir = {};
coverstruct.mFiles = {};

% get the contents of this directory
directorycontents = dir(directory);

% for each m-file, mcov_profile2coverage
mfiles = dir(fullfile(directory, '*.m'));
% sort the mfiles alphabetically
if(~isempty(mfiles))
    [mfilenames, sortedindices] = sort({mfiles.name});
    mfiles = mfiles(sortedindices);
end
numberofmfiles = length(mfiles);
for counti = 1 : numberofmfiles
    curfile = mfiles(counti);
    fullfilepath = fullfile(currentdirectory, curfile.name);
    coverstruct.mFiles{counti} = mcov_profile2coverage(fullfilepath, profileData);
    
    % add the collected data to the sum for the directory
    coverstruct.numExecutableLines = coverstruct.numExecutableLines + ...
        coverstruct.mFiles{counti}.numUsefulLines;
    coverstruct.numCoveredLines = coverstruct.numCoveredLines + ...
        coverstruct.mFiles{counti}.numHitLines;
    coverstruct.numLinesOfCode = coverstruct.numLinesOfCode + ...
        coverstruct.mFiles{counti}.numTotalLines;
    coverstruct.numMFiles = coverstruct.numMFiles + 1;
    if coverstruct.mFiles{counti}.numHitLines
        coverstruct.numHitFiles = coverstruct.numHitFiles + 1;
    end
end

% convert the cell array to a struct array
coverstruct.mFiles = [coverstruct.mFiles{:}];

% for each directory, mcov_directorycoverage
directoryindices = findDirectories(directorycontents);
childdirectories = directorycontents(directoryindices);
numberofdirectories = length(childdirectories);
directorycount = 0;
for counti = 1 : numberofdirectories
    curdir = childdirectories(counti);
    % skip over any directories we know we don't want to look into.
    if(isempty(strmatch(curdir.name, skipdir, 'exact')))
        directorycount = directorycount + 1;
        % add the collected data to the sum for the directory
        coverstruct.childDir{directorycount} = mcov_directorycoverage(fullfile(directory, curdir.name), ...
            profileData);
        coverstruct.numExecutableLines = coverstruct.numExecutableLines + ...
            coverstruct.childDir{directorycount}.numExecutableLines;
        coverstruct.numCoveredLines = coverstruct.numCoveredLines + ...
            coverstruct.childDir{directorycount}.numCoveredLines;
        coverstruct.numLinesOfCode = coverstruct.numLinesOfCode + ...
            coverstruct.childDir{directorycount}.numLinesOfCode;
        coverstruct.numMFiles = coverstruct.numMFiles + ...
            coverstruct.childDir{directorycount}.numMFiles;
        coverstruct.numHitFiles = coverstruct.numHitFiles + ...
            coverstruct.childDir{directorycount}.numHitFiles;
    end
end

% covert the cell array to a struct array
coverstruct.childDir = [coverstruct.childDir{:}];

% calculate the coverage for this directory
if(coverstruct.numExecutableLines ~= 0)
	coverstruct.percentCov = 100*(coverstruct.numCoveredLines/coverstruct.numExecutableLines);
else
    coverstruct.percentCov = 0;
end

return;

function z = findDirectories( directorycontents )
%FINDDIRECTORIES
%
% given an array of structures from a call to dir(), removeFiles
% returns an array of structures containing only the directories
% from the original array.

directoryindices = [];

for counti = length(directorycontents) : -1 : 1
    if(directorycontents(counti).isdir)
        directoryindices(end + 1) = counti;
    end
end


z = directoryindices;
return;
