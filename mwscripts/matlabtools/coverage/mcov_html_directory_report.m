function summaryURL = mcov_html_directory_report(coverstruct, outputpath)
% MCOV_HTML_DIRECTORY_REPORT
%
% function summaryURL = mcov_html_directory_report(coverstruct, outputpath)
% 
% mcov_html_directory_report takes a structure generated by mcov_directorycoverage
% and a path to a directory for output and creates a summary file in html and, if 
% necessary, creates a directory structure containing html files showing the coverage
% for those directories.  mcov_html_directory_report returns the path to the main 
% summary file.
%
% See also MCOV_DIRECTORYCOVERAGE, MCOV_HTML_MFILE_REPORT.

%   $Revision: 1.3 $  $Date: 2006/01/04 10:46:26 $

% if the coverstruct passed in has a name starting with matlabroot
% chop off matlabroot
mdircovered = qetruncatepathfromdir(coverstruct.name, 'toolbox');

% coax the summary name into something nice
summaryname = strrep(mdircovered, filesep, '_');
summaryname = strrep(summaryname, ':', '');

% compute the name for the html file we are writing to
summaryname = sprintf('%s_coverage.html', summaryname);

% get the directory name from the cover struct
dirname = getDirName(coverstruct.name);

% test to see if the directory exists in the output directory
% if it doesn't, create it.
% try to create the directory
previousdirectory = pwd;
cd(outputpath);

if(~mkdir(dirname))
    cd(previousdirectory);
    error('Could not create output subdirectory.');
else
    cd(previousdirectory);
    outputpath = fullfile(outputpath, dirname);
end


% try to open the summary file
fid = fopen(fullfile(outputpath, summaryname), 'wt');
if (fid < 0)
    error('Could not open report file for writing.');
end

% write out the general header for the file
writeHeader(fid, mdircovered);

% write the overall summary for the directory
writeSummaryTable(fid,... 
    coverstruct.numMFiles,...
    coverstruct.numHitFiles,...
    coverstruct.numCoveredLines,...
    coverstruct.numExecutableLines,...
    coverstruct.percentCov);

% write out the coverage summary data for each directory
% below this one
writeDirectoryList(fid, coverstruct, outputpath);

% write out the coverage summary data for the m-files
% in this directory
writeFunctionList(fid, coverstruct, outputpath);

% close the the header
writeFooter(fid);

% close the file
fclose(fid);

summaryURL = mcov_url_escape([dirname '/' summaryname]);

return;

%%%
%%% Anchor
%%%
function out = Anchor(str,name)
% Turns a string into an HTML named anchor.

out = sprintf('<a name="%s"> %s </a>', name, str);

return;

%%%
%%% PrintHTMLFunctionList
%%%
function writeFunctionList(fid, coverstruct, outputpath)

% Print the list of functions in a table.
structArray = coverstruct.mFiles;
if(~isempty(structArray))
    % sort the struct array alphabetically
    filenames = {structArray.mfileName};
    [filenames, sortedindices] = sort(filenames);
    structArray = structArray(sortedindices);
    
    % output the table headers
    fprintf(fid, '<h2> %s </h2> \n\n', Anchor('Function List', 'Function List'));
    fprintf(fid, '<table border=1>\n');
    fprintf(fid, '<th align=center> Name </th>\n');
    fprintf(fid, '<th align=center> Coverage </th>\n');
    fprintf(fid, '<th align=center> Hit Lines </th>\n');
    fprintf(fid, '<th align=center> Executable Lines </th>\n');
    fprintf(fid, '</tr>\n');
    
    % output the data as elements of the table
    for k = 1:length(structArray)
        thisStruct = structArray(k);
        
        fprintf(fid, '<tr>\n');
        
        fprintf(fid, '<td> <a href=%s> %s </a> </td>\n', ...
            mcov_html_mfile_report(thisStruct, outputpath), thisStruct.mfileName); 
        
        % If the number of executable lines is zero then mark the coverage,
        % hit lines, and bang for buck as 'n/a' since they are not applicable. 
        % This will affect contents.m and builtin function.
        if(thisStruct.numUsefulLines == 0)
            fprintf(fid, '<td align="center"> %s </td>\n', 'n/a'); 
            fprintf(fid, '<td align="center"> %s </td>\n', 'n/a');
            fprintf(fid, '<td align="center"> %d </td>\n', 0);
            fprintf(fid, '<td align="center"> %s </td>\n', 'n/a');
        else
            %Coverage in percent
            if(thisStruct.coverage==0.0)
                %make the text red
                fprintf(fid, '<td align="center"> <font color="#FF0000"> %5.1f%% </font></td>\n', ...
                    thisStruct.coverage);
            else  
                %normal text
                fprintf(fid, '<td align="center"> %5.1f%% </td>\n', ...
                    thisStruct.coverage);
            end
            
            %Hit Lines
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numHitLines);
            
            %Useful Lines
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numUsefulLines);
        end%if
        
        fprintf(fid, '</tr>\n');
        
    end %for
    
    fprintf(fid, '</table>\n');    
end % if

return;

function writeDirectoryList(fid, coverstruct, outputpath)
structArray = coverstruct.childDir;
if(~isempty(structArray))
    % sort the struct array alphabetically
    filenames = {structArray.name};
    [filenames, sortedindices] = sort(filenames);
    structArray = structArray(sortedindices);  
    
    % Print the list of directories in a table.
    fprintf(fid, '<h2> %s </h2> \n\n', Anchor('Directory List', 'Directory List'));    
    fprintf(fid, '<table border=1>\n');
    fprintf(fid, '<th align=center> Name </th>\n');
    fprintf(fid, '<th align=center> M-Files </th>\n');
    fprintf(fid, '<th align=center> Hit Lines </th>\n');
    fprintf(fid, '<th align=center> Executable Lines </th>\n');
    fprintf(fid, '<th align=center> Missed Files </th>\n');
    fprintf(fid, '<th align=center> Coverage </th>\n');
    fprintf(fid, '</tr>\n');
    
    for k = 1:length(structArray)
        thisStruct = structArray(k);
        
        fprintf(fid, '<tr>\n');
        
        fprintf(fid, '<td> <a href=%s> %s </a> </td>\n', ...
            mcov_html_directory_report(thisStruct, outputpath), getDirName(thisStruct.name)); 
        
        %If the number of executable lines is zero then mark the coverage,
        %hit lines, useful lines, and bang for buck as 'n/a' since they are
        %not applicable. This will affect contents.m and builtin function.
        if(thisStruct.numExecutableLines == 0)
            fprintf(fid, '<td align="center"> %d </td>\n', thisStruct.numMFiles);
            fprintf(fid, '<td align="center"> %s </td>\n', 'n/a'); 
            fprintf(fid, '<td align="center"> %d </td>\n', 0);
            fprintf(fid, '<td align="center"> %d </td>\n', thisStruct.numMFiles);
            fprintf(fid, '<td align="center"> %s </td>\n', 'n/a');
        else
            %Number of M Files
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numMFiles);
            
            %Hit Lines
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numCoveredLines);
            
            %Useful Lines
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numExecutableLines);
            
            %Missed Files
            fprintf(fid, '<td align="center"> %d </td>\n', ...
                thisStruct.numMFiles - thisStruct.numHitFiles);
            
            %Coverage in percent
            if(thisStruct.percentCov==0.0)
                %make the text red
                fprintf(fid, '<td align="center"> <font color="#FF0000"> %5.1f%% </font></td>\n', ...
                    thisStruct.percentCov);
            else 
                %normal text
                fprintf(fid, '<td align="center"> %5.1f%% </td>\n', ...
                    thisStruct.percentCov);
            end
        end%if
  
        fprintf(fid, '</tr>\n');
  
    end %for
  
    fprintf(fid, '</table>\n');
  
end % if

return;

function z = getDirName( directory )
% first try the platform default fileseparator
% if it isn't present and on a pc, use the unix
% separator, otherwise use the pc separator

if(findstr(directory, filesep))
    z = stringtokens(directory, filesep);
elseif( ispc )
    z = stringtokens(directory, '/');
else
    z = stringtokens(directory, '\');
end

z = char(z(end));

return;

function writeHeader(fid, mdircovered)

fprintf(fid, '<html>\n');
fprintf(fid, '<head>\n');
fprintf(fid, '</head>\n');
fprintf(fid, '<body bgcolor="#FFF7DE" link="#247B2B" vlink="#247B2B" > \n\n');

fprintf(fid, '<title>M-Code Coverage Report for %s </title>\n', ...
	mdircovered);
fprintf(fid, '<h2>M-Code Coverage Report for %s </h2>\n', mdircovered);% fprintf(fid, '<table>\n');
% fprintf(fid, '<tr><td align=center><h2>M-Code Coverage Report for %s </h2></td></tr>\n', mdircovered);
% fprintf(fid, '<tr> <td> &nbsp </td> </tr>\n');
% fprintf(fid, '</table>\n');
return;

function writeSummaryTable(fid, nummfiles, numhitfiles, numhitlines, numexecutablelines, coverage)


% fprintf(fid, '<tr><td><font color="#0000FF" >Last updated: %s</font></td><td>&nbsp</td></tr>\n', datestr(now, 'dd-mmm-yyyy'));

% fprintf(fid, '<h2> %s </h2> \n\n', 'Summary');

fprintf(fid, '<table>\n');
% fprintf(fid, '<tr> <td> &nbsp </td> <td> &nbsp </td> </tr>\n');
fprintf(fid, '<tr> <td> Total M-Files: </td>\n');
fprintf(fid, '<td align="right"> %d </td> </tr>\n', ...
  nummfiles);

fprintf(fid, '<tr> <td> Number of Hit M-Files: </td>\n');
fprintf(fid, '<td align="right"> %d </td> </tr>\n', ...
  numhitfiles);

fprintf(fid, '<tr> <td> Total Hit Lines: </td>\n');
fprintf(fid, '<td align="right"> %d </td> </tr>\n', numhitlines );

fprintf(fid, '<tr> <td> Total Executable Lines: </td>\n');
fprintf(fid, '<td align="right"> %d </td> </tr>\n', numexecutablelines );

fprintf(fid, '<tr> <td> Total Code Coverage: </td>\n');
fprintf(fid, '<td align="right"> %5.1f%% </td> </tr>\n', coverage);
fprintf(fid, '<tr><td align=left>Last Updated:</td><td align=right> %s</td></tr>\n', ...
	datestr(now, 'dd-mmm-yyyy'));
fprintf(fid, '</table>\n');

% fprintf(fid, '<p><b>Last updated: %s</b></p>\n', datestr(now, 'dd-mmm-yyyy'));

return;

function writeFooter(fid);

fprintf(fid, '</body>\n');
fprintf(fid, '</html>\n');

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% general utility functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function z = stringtokens(tokenizethis, withthis)
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
