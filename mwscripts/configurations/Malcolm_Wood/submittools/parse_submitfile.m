function [files,reviewers,gecks,desc,summary] = parse_submitfile(filename)
%parse_submitfile - Extracts file names from a submit file
%
%  files = parse_submitfile(filename)
%
% The output is a cell array of strings.

f = mtfilename(filename);
t = readtextfile(f);

files = cell(size(t));
reviewers = '';
gecks = '';
desc = readtextfile(f,true); % return as a string
summary = '';

% State machine to identify the lines which contain file names
FILENAME = 0;
CONTINUE = 1;
state = FILENAME; % expect filename
for i=1:numel(t)
    line = strtrim(t{i});
    if strncmp(line,'CS:',3)
        state = CONTINUE;
    elseif strncmp(line,'CR: ',3)
        reviewers = i_get_reviewers(reviewers,line(4:end));
        state = CONTINUE;
    elseif strncmp(line,'RR: ',3)
        gecks = i_get_gecks(gecks,line(4:end));
        state = CONTINUE;
    elseif state==CONTINUE
        if isempty(line)
            state = FILENAME;
        end
    elseif strncmp(line,'-subject ',9)
        summary = strtrim(line(10:end));
        if ~isempty(summary) && summary(1)=='"' && summary(end)=='"'
            summary = summary(2:end-1);
        end
    elseif strncmp(line,'-foreign ',9)
        line = line(10:end);
        files{i} = i_get_file(line);
    elseif strncmp(line,'-b ',3)
        line = line(4:end);
        files{i} = i_get_file(line);
    elseif strncmp(line,'-',1)
        % Ignore all other lines beginning with "-"
    else
        files{i} = i_get_file(line);
    end
end
files = files(~cellfun(@isempty,files));
end

%------------------------------------------
function file = i_get_file(line)
    hash = line=='#';
    if any(hash)
        ind = find(hash);
        file = strtrim(line(1:ind(1)-1));
    else
        file = line;
    end
end

%------------------------------------------
function reviewers = i_get_reviewers(reviewers,line)
    toks = tokenize(line,',');
    for i=1:numel(toks)
        r = strtrim(toks{i});
        tbr = regexp(r,'tbrb (?<tbrb>.*)','names');
        if ~isempty(tbr)
            r = strtrim(tbr.tbrb);
        end
        if isempty(reviewers)
            sep = '';
        else
            sep = ',';
        end
        if isempty(strfind(reviewers,r))
            reviewers = [reviewers sep r]; %#ok<AGROW>
        end
    end
end

%------------------------------------------
function gecks = i_get_gecks(gecks,line)
    toks = tokenize(line,',');
    for i=1:numel(toks)
        g = strtrim(toks{i});
        if isempty(gecks)
            sep = '';
        else
            sep = ',';
        end
        if isempty(strfind(gecks,g))
            gecks = [gecks sep g]; %#ok<AGROW>
        end
    end
end
