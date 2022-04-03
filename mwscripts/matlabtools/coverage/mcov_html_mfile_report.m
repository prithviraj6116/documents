function outputURL = mcov_html_mfile_report(mfileCoverageInfo, outputDirPath)
% MCOV_HTML_MFILE_REPORT (INFO, OUTPUT) *Internal*
%  Creates an mcoverage html file. INFO is a struct 
%  containing code coverage information for a specific
%  mfile. INFO is usually produced from MCOV_PROFILE2COVERAGE.
%  OUTPUT is the output directory where the html file will
%  be created.
% 

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:41 $

% Original Author: Vijay Raghavan

if(nargin == 1)
   outputDirPath = pwd;
end

% create the url to output for this file
htmlfilename = [mfileCoverageInfo.mfileNameWithoutPrefix, '.html'];
outputURL = htmlfilename;

% open the file
[fphtml message1] = fopen(fullfile(outputDirPath, htmlfilename), 'w');

% check if an error was raised when opening the output file
if ~isempty(message1)
    fprintf('fopen error with %s ', outputURL);
    error(message1);
end  

% check if an error was raised when opening the m-file
[fpSource, message2] = fopen(mfileCoverageInfo.fullPathNameOfMfile,'r');
if ~isempty(message2)
    fprintf('fopen error with %s ', mfileCoverageInfo.fullPathNameOfMfile);
    error(message2);
end  

% output the file header
fprintf(fphtml,'<html>\n');
fprintf(fphtml,'<head>\n');
fprintf(fphtml,'</head>\n');
fprintf(fphtml,'<body bgcolor="#FFF7DE" link="#247B2B" vlink="#247B2B" >\n');

fprintf(fphtml,'<title>M-Code Coverage Report for %s </title>\n',mfileCoverageInfo.mfileName);
fprintf(fphtml,'<h2>M-Code Coverage Report for %s </h2>\n',mfileCoverageInfo.mfileName);

fprintf(fphtml, '<table>\n');

% output the number of hit lines
fprintf(fphtml, '<tr> <td>Total Hit Lines: </td>\n');
fprintf(fphtml, '<td align="right"> %d </td> </tr>\n',...
                 mfileCoverageInfo.numHitLines);

% output the number of executable lines
fprintf(fphtml, '<tr> <td> Total Executable Lines: </td>\n');
fprintf(fphtml, '<td align="right"> %d </td> </tr>\n',...
                 mfileCoverageInfo.numUsefulLines);

% if there are no executable lines in this function then mark coverage as n/a
fprintf(fphtml, '<tr> <td>Coverage:</td>\n');
if(mfileCoverageInfo.numUsefulLines ~= 0)
    fprintf(fphtml, '<td align="right"> %5.1f%% </td> </tr>\n',mfileCoverageInfo.coverage);
else
    fprintf(fphtml, '<td align="right"> n/a </td> </tr>\n');
end

fprintf(fphtml, '</table>\n');
fprintf(fphtml, '<p>Date of generation: %s</p>\n\n', datestr(now,1));


% if there are no functions or only 1 function, do not output the function
% table, otherwise create the function table.
if(mfileCoverageInfo.numFunctionPoints > 1)
    
    fprintf(fphtml,'<h2 align=left><table border>');
    fprintf(fphtml,'<tr>');
    fprintf(fphtml,'<th align=left> <small> FunctionName </small> </th>');
    fprintf(fphtml,'<th align=left> <small> Hit Lines </small> </th>');
    fprintf(fphtml,'<th align=left> <small> Executable Lines </small> </th>');
    fprintf(fphtml,'<th align=left> <small> Coverage </small> </th>');
    fprintf(fphtml,'</tr>');
    
    for i=1:mfileCoverageInfo.numFunctionPoints
        fprintf(fphtml,'<tr>');
        funcName = char(mfileCoverageInfo.FunctionNames{i});
        fprintf(fphtml,'<td align=left><A HREF=#%s>%s</a></td>',funcName,funcName);
        fprintf(fphtml,'<td align=center>%d</td>',mfileCoverageInfo.FuncHitLines(i));
        fprintf(fphtml,'<td align=center>%d</td>',mfileCoverageInfo.FuncUsefulLines(i));
        fprintf(fphtml,'<td align=center>%3.1f%%</td>',mfileCoverageInfo.FuncCoverage(i));
        fprintf(fphtml,'<tr>\n');
    end
    fprintf(fphtml,'</table></h2>\n');
    
end
%------------------------------------------------------------------

fprintf(fphtml,'<pre>\n');
fprintf(fphtml,'\n');
fprintf(fphtml,'Note: <font color="#FF0000" >Lines not covered are red</font>.\n'); 
fprintf(fphtml,'      <font color="#0000FF" >Function names are blue</font>.\n');
fprintf(fphtml,'      <font color="#AFAFAF" >Comment lines are grey</font>.\n');
fprintf(fphtml,'      <font color="#000000" >Executed lines are black</font>.\n');
fprintf(fphtml,'****************************************************\n'); 
fprintf(fphtml,'\n'); 

currentFunction = 1;

% loop through m-file----------------------------------------------------------------
for t = 1:mfileCoverageInfo.numTotalLines
   thisLine = fgetl(fpSource);
   if(mfileCoverageInfo.hitLines(t)==0) 
      fprintf(fphtml,'<font color="#FF0000" >%5d %s</font>\n',t,thisLine); 
   elseif(mfileCoverageInfo.hitLines(t)==1) 
      fprintf(fphtml,'<font color="#000000" >%5d %s</font>\n',t,thisLine); 
   elseif(mfileCoverageInfo.hitLines(t)==3 & ~isempty(findstr('function',thisLine)) )
      
      funcName = char(mfileCoverageInfo.FunctionNames{currentFunction});
      currentFunction = currentFunction + 1;
      fprintf(fphtml,'<h2><a NAME=%s></a></h2>',funcName);
      fprintf(fphtml,'<font color="#0000FF" >%5d %s</font>\n',t,thisLine);
      
   elseif(mfileCoverageInfo.hitLines(t)==3)
      fprintf(fphtml,'<font color="#0000FF" >%5d %s</font>\n',t,thisLine);
   else 
      fprintf(fphtml,'<font color="#AFAFAF" >%5d %s</font>\n',t,thisLine); 
   end 
end
fprintf(fphtml,'</pre>\n'); 

fprintf(fphtml,'</body>\n');
fprintf(fphtml,'</html>\n');

fclose(fphtml);
fclose(fpSource);

return;
