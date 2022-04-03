function z = mcov_mfileinfo(pathtofile)
% MCOV_MFILEINFO 
%
% mcov_mfileinfo(pathtofile) parses useful data out of an m-file and returns it 
% in a structure with the following fields:
% 
% emptylines - an array of the line numbers of comments lines and blank lines
% continuedlines - an array of the line numbers of lines that are continued
% functionnames - a cell array of strings containing the names of all
%               - functions in this m-file
% functionlines - an array of the line numbers of the function lines
% functiontotalexecutablelines - an array of numbers signifying the number
%                              - of executable lines per function
% totalexecutablelines - a single number containing the total number of executable
%                      - lines for the m-file
% totalnumberoflines - a single number containing the total number of lines in the m-file

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:41 $

% PARSING CONSTANTS
COVER_EMPTY = 'COVER_EMPTY:';
COVER_CONTINUED = 'COVER_CONTINUED:';
COVER_FUNCTIONS = 'COVER_FUNCTIONS:';
COVER_FUNCTION_LINES = 'COVER_FUNCTION_LINES:';
COVER_FUNCTION_NUMBER_OF_EXECUTABLE_LINES = 'COVER_FUNCTION_NUMBER_OF_EXECUTABLE_LINES:';
COVER_NUMBER_OF_EXECUTABLE_LINES = 'COVER_NUMBER_OF_EXECUTABLE_LINES:';
COVER_NUMBER_OF_LINES = 'COVER_NUMBER_OF_LINES:';
COVER_REVISION='COVER_REVISION:';

% initialize the data structure
z.emptylines = [];
z.continuedlines = [];
z.functionnames = [];
z.functionlines = [];
z.functiontotalexecutablelines = 0;
z.totalexecutablelines = 0;
z.totalnumberoflines = 0;
z.revision = '';

perlScript = 'emptylines.pl';
perlScript = fullfile(strrep(which(mfilename), [mfilename '.m'], ''), perlScript);

if ispc
   pathtofile = strrep(pathtofile, '/', filesep);
   [returncode, data] = unix([matlabroot '\sys\perl\win32\bin\' sprintf('perl "%s" < "%s"',perlScript, pathtofile)]);
else
   pathtofile = strrep(pathtofile, '\', filesep);
   [returncode, data] = unix(sprintf('perl "%s" < "%s"',perlScript, pathtofile));
end

% parse data and make the structure
% break data up by lines
datalines = stringtokens(data, 10);

% find the empty lines
stringindex = strmatch(COVER_EMPTY, datalines);
if(~isempty(stringindex))
    z.emptylines = str2num(char(strrep(datalines(stringindex), COVER_EMPTY, '')));
end

% find the continued lines
stringindex = strmatch(COVER_CONTINUED, datalines);
if(~isempty(stringindex))
    z.continuedlines = str2num(char(strrep(datalines(stringindex), COVER_CONTINUED, '')));
end

% get the function lines
stringindex = strmatch(COVER_FUNCTION_LINES, datalines);
if(~isempty(stringindex))
    z.functionlines = str2num(char(strrep(datalines(stringindex), COVER_FUNCTION_LINES, '')));
end

% get the number of executable lines
stringindex = strmatch(COVER_NUMBER_OF_EXECUTABLE_LINES, datalines);
if(~isempty(stringindex))
    z.totalexecutablelines = str2num(char(strrep(datalines(stringindex), COVER_NUMBER_OF_EXECUTABLE_LINES, '')));
end

% get the number of function executable lines
stringindex = strmatch(COVER_FUNCTION_NUMBER_OF_EXECUTABLE_LINES, datalines);
if(~isempty(stringindex))
    z.functiontotalexecutablelines = str2num(char(strrep(datalines(stringindex), COVER_FUNCTION_NUMBER_OF_EXECUTABLE_LINES, '')));
end

% get the total number of lines
stringindex = strmatch(COVER_NUMBER_OF_LINES, datalines);
if(~isempty(stringindex))
    z.totalnumberoflines = str2num(char(strrep(datalines(stringindex), COVER_NUMBER_OF_LINES, '')));
end

% get the file revision number
stringindex = strmatch(COVER_REVISION, datalines);
if(~isempty(stringindex))
    z.revision = char(strrep(datalines(stringindex), COVER_REVISION, ''));
end

% get the function names
z.functionnames = stringtokens(char(strrep(datalines(strmatch(COVER_FUNCTIONS,datalines)), COVER_FUNCTIONS, '')), ' ');

return;

function z = stringtokens(tokenizethis, withthis)
z  = {};

while(1)
    [T, tokenizethis] = strtok(tokenizethis, withthis);
    if(~isempty(T))
	    z = cat(1, z, {T});
    else
        break;
    end
end

return;
