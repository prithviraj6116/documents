function headertree(filename,full3p)
% headertree - Determines the hierarchy of headers included by the specified file.
%
%  headertree(filename)
%  headertree(filename,true) % recurse into 3rd party header hierarchies
%
% The specified file is preprocessed (unless it is the preprocessor output
% itself, in a file with extension "cpp_i") and that is analyzed to find
% the hierarchy of included headers.
%
% Three text files are created:
%   <filename>_headertree  showing the hierarchy, with dots to indicate depth
%   <filename>_unclassified  containing a sorted list of the absolute paths
%                          of all of these headers.
%   <filename>_headertree  containing a sorted list of headers with prefixes
%                          indicating where in the source tree they come from.

if nargin<2
    full3p = false;
end

logfile_prefix = [filename '_'];
logfile_prefix = regexprep(logfile_prefix,'_RELEASE_SUPER-STRICT\.cpp_i','.cpp');

if strcmp(filename(end-1:end),'_i')
    % Already an _i file
   i_headertree(filename,logfile_prefix,full3p); 
   return;
end

output = preprocess(filename);
i_headertree(output,logfile_prefix,full3p);
delete(output);

end

%-----------------------------------
function i_headertree(preprocessor_output,logfile_prefix,full3p)

[f,msg] = fopen(preprocessor_output,'rt');
if f==-1
    error('mwood:headertree:open_file','%s',msg);
end
cleanup = onCleanup(@() fclose(f));

started = false;
processed_line_count = 1;
header_count = 0;
tree_count = 0;
classified = cell(20000,1);
unclassified = cell(20000,1);
tree = cell(20000,1);
prev_header_type = 'u';
while true
    t = fgetl(f);
    if t==-1
        break;
    end
    if ~started
        if strncmp(t,' * .',4)
            started = true;
        else
            continue;
        end
    elseif ~strncmp(t,' * .',4)
        break;
    end
    if strcmp(t,' * sbcc-info-end */')
        break;
    end

    [depth,t] = getdepth(t);
    [type,filename,canonical] = classifyheader(t);
    
    % Don't print nested system or 3rd party headers.
    is3ptree = (strcmp(prev_header_type,'3') || strcmp(prev_header_type,'s'))...
        && (strcmp(type,'3') || strcmp(type,'s'));
    
    if full3p || ~is3ptree
        tree{tree_count+1} = sprintf('%s%s',repmat('. ',1,depth),filename);
        tree_count = tree_count + 1;
    end
    prev_header_type = type;
    classified{header_count+1} = filename;
    unclassified{header_count+1} = canonical;
    header_count = header_count + 1;
    processed_line_count = processed_line_count + 1;
    if processed_line_count>20000
        disp('Overrun');
        return;
    end
end

tree = tree(1:tree_count);

classified = classified(1:header_count);
classified = unique(classified);

unclassified = unclassified(1:header_count);
unclassified = unique(unclassified);

plines = linecount(preprocessor_output);
summary = {'PreprocessedLines',...
    sprintf('%d',plines),...
    };

tree_log = mtfilename([logfile_prefix 'headertree']);
writetextfile(tree_log,tree);
fprintf('Writing <a href="matlab:edit %s">%s</a>\n',getabs(tree_log),getshortname(tree_log));

unclassified_log = mtfilename([logfile_prefix 'headerlist_unclassified']);
writetextfile(unclassified_log,unclassified);
fprintf('Writing <a href="matlab:edit %s">%s</a>\n',getabs(unclassified_log),getshortname(unclassified_log));

classified_log = mtfilename([logfile_prefix 'headerlist_classified']);
writetextfile(classified_log,classified);
fprintf('Writing <a href="matlab:edit %s">%s</a>\n',getabs(classified_log),getshortname(classified_log));

summaryfile = mtfilename([logfile_prefix 'summary']);
writetextfile(summaryfile,summary);

fprintf('%d unique headers found.\n',numel(classified));
fprintf('Preprocessed line count: %d\n',plines);
end

function [depth,filename] = getdepth(filename)
    toks = regexp(filename,' * (?<dots>\.)* (?<filename>.*)','names');
    depth = numel(toks.dots);
    filename = toks.filename;
end

