function mcov_html_toolbox_report(toolboxdata, summaryfile, mappingfile)
% MCOV_HTML_TOOLBOX_REPORT
%
% mcov_html_toolbox_report(toolboxdata, summaryfile, mappingfile)
%
% mcov_html_toolbox_report is designed to work intimately with mcov_generate_reports.
% It generates an html file containing the overall coverage summary for the toolbox
% directory. 
%
% toolboxdata is a structure containing pertinant information about the coverage of 
% MATLAB's toolbox directory.  
% 
% outputfile is the path to the html file that should contain the summary.
%
% The toolboxdata structure should have the following fields:
% numberofmfiles = the number of mfiles in the toolbox directory
% totallinsesofcode = the total lines of executable code in the toolbox directory
% totalhitlines = the total number of hit lines for the toolbox directory
% coverage = percent coverage for the toolbox directory
% directories = an array of structures containing information about toolbox subdirectory
%         each of the structures in the directories array have the following structure:
%         name = the path to the directory
%         numMFiles = the number of mfiles for the directory
%         numCoveredLines = the total number of covered lines for the directory
%         numExecutableLines = the total number of executable lines for the directory
%         percentCov = the percent coverage for the directory
%         URLtosummary = a string containing the relative path to the html file generated for
%                        the specific directory
%         testdirectories = a cell array of the test directories run on this source directory
%
% See also MCOV_GENERATE_REPORTS, MCOV_HTML_MFILE_REPORT, MCOV_HTML_DIRECTORY_REPORT.

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:41 $

% html place holder
tableentries = '';

if(nargin > 1 & ~isempty(summaryfile))
    % open the html file for output
    fid = fopen(summaryfile, 'w');
    
    % write out the header for the page
    fprintf(fid, writePageHeader);
    
    if(~isempty(toolboxdata))
        
        % output summary for the whole tree
        summary = writeCoverageSummary(toolboxdata);
        fprintf(fid, '%s', summary);
                
        % if we will be creating a mapping file, link to it from this page
        if(nargin == 3)
            tokens = stringtokens(mappingfile, filesep);
            fprintf(fid, writeMapPageLink(tokens{end}));
        end
        
        for counti = 1 : length(toolboxdata.directories)
            % generate a table entry for this data
            tableentries = strcat(tableentries, writeCoverageTableEntry( toolboxdata.directories(counti) ));
        end
        
        % output table with entries broken down by directory
        fprintf(fid, '%s', writeDirectoryTableTitle);
        fprintf(fid, '%s', table([writeCoverageTableHeader, tableentries], 1));
        
        % close the html tags on the page
        fprintf(fid, writePageFooter);
        
    end   
    
    % close the file handle for the page
    fclose(fid);   
    
end

% if mappingfile was passed in write out the mapping file
if(nargin == 3)
    % open the html for output
    fid = fopen(mappingfile, 'w');
    
    if(~isempty(toolboxdata))
        % write out the page that displays the source to test mapping
        testsmapped = {};
        tableentries = '';
        
        % build the table of source to test mappings 
        numberofsourcedirectories = length(toolboxdata.directories);
        for counti = 1 : numberofsourcedirectories
            tableentries = strcat(tableentries, source2TestTableEntry(toolboxdata.directories(counti).name,...
                toolboxdata.directories(counti).testdirectories));

            % build up the list of tests mapped
            testsmapped = union(testsmapped, toolboxdata.directories(counti).testdirectories);
        end
        
        % start the html page
        fprintf(fid, source2TestHeader);
        fprintf(fid, table(tableentries, 1));
                
        % output the test directories that weren't mapped to anything
        fprintf(fid, '%s', writeTestListTitle);
        fprintf(fid, '%s', writeList(setdiff(toolboxdata.testdirectories, testsmapped)));

        % finish the html page
        fprintf(fid, source2TestFooter);
        
    end
    
    % close the page
    fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HTML Utilities %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function z = writePageHeader(directoryname)
% write out the html header for the page

z = [sprintf('<html>\n')];
z = [z sprintf('<head>\n')];
z = [z sprintf('</head>\n')];
z = [z sprintf('<body bgcolor="#FFF7DE" link="#247B2B" vlink="#247B2B" >\n')];

z = [z sprintf('<title>M-Code Coverage Report - %s </title>\n', getDate)];
z = [z sprintf('<h2>M-Code Coverage Report - %s </h2>\n', getDate)];

return;

function z = writeMapPageLink( mappagename )
	% writes out the link to the source to test mapping page
	z = sprintf('<a href=%s>Source to test mappings for %s</a><br>\n', mappagename, getDate);

return;

function z = writePageFooter()
% write out the footer for the page

z = sprintf('</body>\n</html>\n');

return;

function z = writeCoverageSummary( coveragedata )
% write out the summary for all the coverage

z = table([coverageSummaryRow('Total M-files: ', ...
        sprintf('%d', coveragedata.numberofmfiles)), ...
    coverageSummaryRow('Total Hit Lines: ', ...
        sprintf('%d', coveragedata.totalhitlines)),...
    coverageSummaryRow('Total Executable Lines: ',...
        sprintf('%d', coveragedata.totalexecutablelines)),...
    coverageSummaryRow('Total Code Coverage: ', ...
        sprintf('%2.1f%%', 100*(coveragedata.totalhitlines/coveragedata.totalexecutablelines)))]);

return;

function z = coverageSummaryRow( rowname, rowdata )
% put the strings rowname and row data into a row formatted for the 
% the coverage summary table
z = sprintf('<tr><td align=left> %s </td><td align=right> %s </td></tr>\n', rowname, rowdata);

return;

function z = writeCoverageTableHeader()
% write out the table headers for the table of directories
z = tableheader('Source Directory',...
    'M-Files',...
    'Hit Lines',...
    'Executable Lines',...
    'Coverage');

return;


function z = writeCoverageTableEntry( coveragedata )
% returns a string containing a single entry formatted for the 
% directory coverage table
name = qetruncatepathfromdir(coveragedata.name,'toolbox');
if(isempty(coveragedata.URLtosummary))
    z = tablerow(sprintf(['<table border=0 width="100%%"><tr><td align=left>%s</td>',...
			 '<td align=right><font color="5A5A5A">DNR</font></td></tr></table>'], name),...
        sprintf('%d', coveragedata.numMFiles),...
        sprintf('%d', coveragedata.numCoveredLines),...
        sprintf('%d', coveragedata.numExecutableLines),...
        sprintf('%2.1f%%', coveragedata.percentCov));  
elseif(coveragedata.numExecutableLines == 0)
    z = tablerow(sprintf('<a href=%s>%s<a>', coveragedata.URLtosummary, name),...
        sprintf('%d', coveragedata.numMFiles),...
        sprintf('%d', coveragedata.numCoveredLines),...
        sprintf('%d', coveragedata.numExecutableLines),...
        sprintf('%s', 'n/a'));
else  
    z = tablerow(sprintf('<a href=%s>%s<a>', coveragedata.URLtosummary, name),...
        sprintf('%d', coveragedata.numMFiles),...
        sprintf('%d', coveragedata.numCoveredLines),...
        sprintf('%d', coveragedata.numExecutableLines),...
        sprintf('%2.1f%%', coveragedata.percentCov));
end 

return;

function z = writeDirectoryTableTitle()
% simply writes out the title for the directory coverage table
z = sprintf('<h2> Directory List </h2>\n');
z = [z, sprintf(['<pre>\n',...
		 'Note:\n',...
		 '     <font color="5A5A5A">DNR</font>', ...
		 ' - tests for the source directory Did Not Run.\n',...
		 '</pre>\n'])];
return;

function z = tableheader(varargin)
% write each element of varargin in separate cells as table headers
% start the table row
z = '<tr>';

% add a variable number of data cells
for counti = 1 : nargin
    z = [z, sprintf('<th align=center>%s</th>', char(varargin(counti)))];
end

% close the table row
z = [z, sprintf('</tr>\n')];

return;

function z = tablerow(varargin)
% put each element of varargin in individual cells in a table row

% start the table row
z = '<tr>';

% add a variable number of data cells
for counti = 1 : nargin
    if(counti == 1)
        z = [z, sprintf('<td align=left>%s</td>', char(varargin(counti)))];
    else
        z = [z, sprintf('<td align=center>%s</td>', char(varargin(counti)))];
    end
end

% close the table row
z = [z, sprintf('</tr>\n')];

return;

function z = table(tablecontents, border)
% put table contents in a table with border width equal to border

if(nargin == 2)
    z = sprintf('<table border=%d>\n%s</table>', border, tablecontents);
else
    z = sprintf('<table>\n%s</table>', tablecontents);
end

return;

function z = source2TestHeader()

z = sprintf('%s\n%s\n%s\n%s\n%s\n%s\n',...
    '<html>',...
    '<body bgcolor="#FFF7DE">',...
    ['<title>Source To Test Mappings - ', getDate, '</title>'],...
    ['<h2>Source To Test Mappings - ', getDate, '</h2>'],...
    ['<p>M-code coverage is collected and displayed once a week (every Sunday).',...
        'Any changes made to the coverage mapping will not show up in this report',...
        'until the next time coverage information is collected.</p>'],...
    '<p><a href="./mcovutil/mcovmap.cgi">Edit Mapping</a></p>');
return;

function z = source2TestFooter()

z = sprintf('%s%s',...
    '</body>\n',...
    '</html>');
return;

function z = source2TestTableEntry(sourcedirectory, testdirectories)

mappings = '';
% start the table row
z = '<tr>';
% write out the source directory
z = [z, sprintf('<td valign=top>%s</td>', qetruncatepathfromdir(sourcedirectory,'toolbox'))];
% now write out the test directories used to test that source directory
for counti = 1 : length(testdirectories);
    mappings = [mappings char(testdirectories(counti)) '<br>' char(10)];
end
if(isempty(mappings))
    z = [z, sprintf('<td>%s</td>','No Test Directories Found')];
else
    z = [z, sprintf('<td>%s</td>', mappings)];
end

% close the table row
z = [z, sprintf('</tr>\n')];

return;

function z = writeList( cellarray )

z = '';

clen = length(cellarray);

for counti = 1 : clen
    z = [z sprintf('%s<br>\n', char(cellarray(counti)))];
end

return;

function z = writeTestListTitle()

z = sprintf('<h2>%s</h2>', 'Test Directories <u>Not</u> Mapped');

return;

function z = getDate()
% get date outputs a string containing the current date formatted
% these pages
z = datestr(now, 'mm/dd/yyyy');

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