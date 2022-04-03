function mfileCoverageInfo = mcov_profile2coverage(mfilePath, profileInfo)
%INFO = MCOV_PROFILE2COVERAGE( MFILEPATH, PROFILE) *Internal*
%  Converts profile data into useful m-file coverage 
%  information. MFILEPATH is the name of the mfile with 
%  the full path. PROFILE is an array of structs usually
%  created by profile('info'). 
%
%  The output argument INFO contains coverage information 
%  on the specified mfile with the following fields:
%
%                 mfileName --char array
%    mfileNameWithoutPrefix --char array
%       fullPathNameOfMfile --char array
%                   dateNum --double
%           setOfBlankLines --double array
%            numUsefulLines --double
%             numTotalLines --double
%                  hitLines --double array
%               numHitLines --double
%                  revision --string
%                  coverage --double
%         numFunctionPoints --double
%             FunctionNames --cell array of char arrays
%            FuncTotalLines --double array
%           FuncUsefulLines --double array
%              FuncHitLines --double array
%              FuncCoverage --double array
%
% See also MCOV_MFILEINFO.

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:41 $

% Original Author: Vijay Raghavan

% this function must have two arguments
if (nargin ~= 2)
   error('Two input arguments are required:  the fullpath to an m-file and a profile structure.');
end
% check to make sure that the mfilePath arg is a string
if ( ~ischar(mfilePath) ) 
   error('MFILEPATH must be a string.');
end
% check to see that if profileInfo is not empty, it is a struct
if ( ~isempty(profileInfo) & ~isstruct(profileInfo) ) 
   error('PROFILE must be a structure of profile data.');
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%  process m-file in two easy steps %% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%1) First check that the mfile exists on the path and get information
mfileInfo = get_pathInfo(mfilePath);

%2) Populate a struct containing important information on the 
%mfile and code coverage. Note that the actual mfile text is
%not in this variable so another "which" and file input will
%be required to map the coverage data to the actual mfile.
%But, there is no reason why that information can not be passed
%at some point in the future if needed. 
mfileCoverageInfo = determine_line_coverage(profileInfo, mfileInfo);
     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mfileInfo = get_pathInfo(mfilePath)
%GETPATHINFO
%  get_pathinfo takes a filename and obtains information
%  regarding this file and stores it in a mfileInfo structure
%  with the following fields:
%
%  mfileName -- The name or the mfile 'foo.m'
%  fullPathNameOfMfile -- Absolute path to the mfile 
%                         using the native directory 
%                         structure i.e. 'd:\R11\toolbox\matlab\Joe\foo.m'    
%  mfileNameWithoutPrefix -- 'foo'

%force unix style directories
mfilePath = strrep(mfilePath, '\', '/'); 

% check if m-file exists -isn't there a better way to do this?
if( exist(mfilePath) ~= 2) %2 means m-file, see m-help for 'exist'
   err = sprintf('Can not find %s',mfilePath);
   error(err);
end

% Clip all directory information from the file name
% i.e. 'food/fruit/apple.m' become 'apple.m'
s = findstr(mfilePath, '/'); %determine '/' position within array
if ~isempty(s)
   mfileName = mfilePath(s(end)+1:end);
else
   mfileName = mfilePath;
end

% strip the .m from the end of the filename
if strcmp(mfileName(end-1:end),'.m')
   mfileNameWithoutPrefix = mfileName(1:end-2);
else
   error('something is wrong');
end

mfileInfo.mfileName = mfileName;
mfileInfo.fullPathNameOfMfile = mfilePath;
mfileInfo.mfileNameWithoutPrefix = mfileNameWithoutPrefix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function coverageInfo = determine_line_coverage(profileInfo, pathInfo)
%DETERMINE_LINE_COVERAGE  
%  determine_line_coverage coordinates the analysis process 
%  by getting the executed lnes for the current mfile, marking
%  all of the lines, and generating a coverage info structure.

  executedLines = getExecutedLines(profileInfo, pathInfo.fullPathNameOfMfile);
  lineInfo = getLineInfo(pathInfo.fullPathNameOfMfile, executedLines);
  
  coverageInfo.mfileName = pathInfo.mfileName;
  coverageInfo.mfileNameWithoutPrefix = pathInfo.mfileNameWithoutPrefix;
  coverageInfo.fullPathNameOfMfile = pathInfo.fullPathNameOfMfile;
  coverageInfo.dateNum = now; 
  coverageInfo.setOfBlankLines = lineInfo.emptylines;  
  coverageInfo.numUsefulLines = lineInfo.totalUsefulLines; 
  coverageInfo.numTotalLines = lineInfo.numTotalLines; 
  coverageInfo.hitLines = lineInfo.lineMarks;
  coverageInfo.revision = lineInfo.revision;
  coverageInfo.numHitLines = length(executedLines); %length(find(lineInfo.lineMarks==1));
 
  if(coverageInfo.numUsefulLines==0) 
     coverageInfo.coverage = 100.0; 
  else 
     coverageInfo.coverage = coverageInfo.numHitLines/coverageInfo.numUsefulLines*100.0; 
  end 
  
  % Function point coverageInfo--------------------------------------------------
  coverageInfo.numFunctionPoints = length(lineInfo.Functions);
  coverageInfo.FunctionNames = lineInfo.Functions;
  coverageInfo.FunctionsLineNums = lineInfo.FunctionsLines;
  coverageInfo.FuncTotalLines = zeros(1,coverageInfo.numFunctionPoints);
  coverageInfo.FuncUsefulLines = lineInfo.FunctionsExecutableLines;
  coverageInfo.FuncHitLines = zeros(1,coverageInfo.numFunctionPoints);
  coverageInfo.FuncCoverage = zeros(1,coverageInfo.numFunctionPoints);
  
  startPoints = coverageInfo.FunctionsLineNums + 1;
  stopPoints = [coverageInfo.FunctionsLineNums-1, coverageInfo.numTotalLines];
  
  % calculate function coverage percentages.
  for funs = 1:coverageInfo.numFunctionPoints
     
     code = 0;
     useful = coverageInfo.FuncUsefulLines(funs);
     hit = length(find(executedLines >= startPoints(funs) & executedLines <= stopPoints(funs+1)));
     coverageInfo.FuncHitLines(funs) =  hit;
     
     if(useful==0)
        coverageInfo.FuncCoverage(funs) = 100.0;
     else
        coverageInfo.FuncCoverage(funs) = hit / useful * 100;
     end
  end % end calculate function point coverages.
 
  return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lineInfo = getLineInfo(mFilepath, executedLines)
%GET_LINE_INFO
%  This function tallies the various line types within
%  a given m-file. line types include blank lines, comment
%  lines, end lines, function headers, and executed lines.
%  This function returns a lineInfo structure, which contains
%  the total number of lines within the m-file, an index which
%  maintains a line type code for later interpretation, and a list
%  of function names.
%  lineMark codes
%  0 = line has not been executed
%  1 = line has been executed
%  2 = line is useless
%  3 = function header
%  4 = function header continuation

% Pass file name into mcov_mfileinfo to find out information about the mfile.
mfileLineInfo = mcov_mfileinfo(mFilepath);

lineInfo.numTotalLines = mfileLineInfo.totalnumberoflines;
lineInfo.totalUsefulLines = mfileLineInfo.totalexecutablelines;
lineInfo.lineMarks = zeros(1,lineInfo.numTotalLines);
lineInfo.Functions = mfileLineInfo.functionnames;
lineInfo.FunctionsLines = mfileLineInfo.functionlines;
lineInfo.FunctionsExecutableLines = mfileLineInfo.functiontotalexecutablelines;
lineInfo.emptylines = mfileLineInfo.emptylines;
lineInfo.revision = mfileLineInfo.revision;

currentFunction = 1; % temporary counter variable.

% mark all hit lines.
lineInfo.lineMarks(executedLines) = 1;
lineInfo.lineMarks(mfileLineInfo.emptylines) = 2;
lineInfo.lineMarks(mfileLineInfo.functionlines) = 3;

% Need to go both forwards and backwards through the continued
% lines array in order to get the correct executed lines from the
% continued lines.
for cont = 1:length(mfileLineInfo.continuedlines)
   currlineMark = lineInfo.lineMarks(mfileLineInfo.continuedlines(cont));
   if ( currlineMark == 1 | currlineMark == 3)
      lineInfo.lineMarks(mfileLineInfo.continuedlines(cont)+1) = currlineMark;
   end
end
for cont = length(mfileLineInfo.continuedlines):-1:1
   nextlineMark = lineInfo.lineMarks(mfileLineInfo.continuedlines(cont)+1);
   if ( nextlineMark == 1 | nextlineMark == 3)
      lineInfo.lineMarks(mfileLineInfo.continuedlines(cont)) = nextlineMark;
   end
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function executedLines = getExecutedLines(profileInfo, mFileWithPath)
% GETEXECUTEDLINES determines the executed lines of an mfile.
%  getExecutedLines takes profiler information and the mfile
%  and returns a cell array containing indices of all of the lines which
%  have been executed within the current mfile.

  executedLines = [];
  foundFile = logical(0);
  passedinmfile = mFileWithPath;
  s = findstr(passedinmfile, 'toolbox');
  if ~isempty(s)   
     passedinmfile = passedinmfile(s:end);
  end
  passedinmfile = lower(passedinmfile);
  passedinmfile = strrep(passedinmfile, '\', '/');
  
  % chop off the 'm' from '.m', this allows us
  % to also find '.p' files
  if( strcmp(passedinmfile(end-1:end), '.m') )
      passedinmfile(end) = ''; 
  end
  
  if ( ~isempty(profileInfo) )

      % MW: performance improving measure
      if isfield(profileInfo,'ProcessedFileNames')
          useprocessed = 1;
      else
          useprocessed = 0;
      end

     if useprocessed
         matches = strmatch(passedinmfile, profileInfo.ProcessedFileNames);
         %if the strings match then get executed line information.
         if ~isempty(matches)
             foundFile = logical(1);
             if length(matches)>1
                 templines = vertcat(profileInfo.FunctionTable(matches).ExecutedLines);
                 executedLines = unique(templines(:,1)');
             else
                executedLines = profileInfo.FunctionTable(matches).ExecutedLines(:,1)';
             end
         end %if 
     else
         for t = 1:size(profileInfo.FunctionTable,1) 
            profiledmfile = profileInfo.FunctionTable(t).FileName;
            %passedinmfile = mfileInfo.fullPathNameOfMfile(1:end-1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Massage strings so that they can be compared 
            % reasonably:
            %  -Clip all matlab root information from the mfile name
            %  -Force lower case of all characters
            %  -Make the directories unix style.
            % For example 'D:\R13\MATLAB\toolbox\FOOBAR\foo.m
            % will become 'toolbox/foobar/foo.m'
            
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
       
            %if the strings match then get executed line information.
            if strmatch(passedinmfile, profiledmfile)
               foundFile = logical(1);
               executedLines = union(executedLines,profileInfo.FunctionTable(t).ExecutedLines(:,1)');
            end %if 
         end %for
     end
     
     %if the file was never found then output a message to console.   
     if(~foundFile)
        disp(sprintf('No profile data for: %s', mFileWithPath));
    else
        disp(sprintf('Processing M-File: %s', mFileWithPath));
     end  %if (~foundFile)
  else
      % if the coverage data is empty print out that the profile
      % data for the desired function was not found, and allow the
      % empty matrix to be passed out
      disp(sprintf('No profile data for: %s', mFileWithPath));
      executedLines = [];
  end %if( ~isempty(profileInfo) )
 
  return;
