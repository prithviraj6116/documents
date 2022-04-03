function [files,action] = get_changeset(changenum)
% get_changeset - return detail of the current Perforce changeset
%
% [files,action] = get_changeset
%
% files is a cell array of strings
% action is a numeric array:
%  -1 for deletion
%   0 for edit
%   1 for addition
%
% Also:
%   -2 for move/delete
%   -2 for move/add

if nargin && ~isempty(changenum)
    if ~ischar(changenum)
        changenum = sprintf('%d',changenum);
    end
    suffix = [' -c ' changenum];
else
    suffix = '';
end
[status,output] = system(['p4 opened' suffix]);
if status
    error('mwood:tools:p4','Failed to get changeset: %s',output);
end

lines = strsplit(output,newline);
[details,~] = regexp(lines,'(?<name>.*)#\d* - (?<action>[\w\/]*) ','names');
files = cell(size(details));
action = zeros(size(details));

for i=1:numel(details)
    f = details{i};
    if numel(f)==0
        continue; % no match on this line
    end
    % Match //mw/Bcluster/
    [start,finish] = regexp(f.name,'\/\/mw\/[^\/]*\/');
    if ~isempty(start)
        files{i} = f.name(finish+1:end);
    else
        % Problem.
        [start,finish] = regexp(f.name,'\/\/mwpdb\/[^\/]*\/[^\/]*\/[^\/]*\/');
        if ~isempty(start)
            files{i} = f.name(finish+1:end);
        else
            % Problem
            files{i} = f.name;
        end
    end
    %if strncmp(f.action,'move/',5)
    %    f.action = f.action(6:end);
    %end
    switch f.action
        case 'edit'
            action(i) = 0;
        case 'add'
            action(i) = 1;
        case 'delete'
            action(i) = -1;
        case 'move/add'
            action(i) = 2;
        case 'move/delete'
            action(i) = -2;
        otherwise
            warning('mwood:tools:p4','Unknown action: %s',f.action);
    end
end
files = files(~cellfun(@isempty,files));

