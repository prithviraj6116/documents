function headers = get_header_list(modfolder,sort)
% get_header_list - returns names of all exported headers in this module
%
% headers = get_header_list
%
% Names are relative to the export/include/<module> folder.

if ~nargin || isempty(modfolder)
    modfolder = pwd;
end
[~,modname] = fileparts(modfolder);

% Read headers.mk
headers_dir = fullfile(modfolder,'export','include',modname);
assert(exist(headers_dir,'dir')~=0);
headers_mk = fullfile(headers_dir,'headers.mk');
mk = readtextfile(mtfilename(headers_mk));

% Generate a temporary makefile which prints out the value of the
% EXPORT_HEADERS variable.
mk{end+1} = '';
mk{end+1} = 'listfiles:';
mk{end+1} = sprintf('\t@echo $(EXPORT_HEADERS)');
mk{end+1} = '';
writetextfile(mtfilename('listfiles.mk'),mk);
clean_mk = onCleanup(@() delete('listfiles.mk'));

% Run this makefile
[status,output] = system('sbmake -f listfiles.mk listfiles');
if status~=0
    error('mwood:headers:listfiles','%s',output);
end

% sbmake prints out several lines that we don't need.  Just get the last
% line, which is the list of headers.
lines = mt_tokenize(output,char(10));
files = lines{end};
files = mt_tokenize(files); % use whitespace as separator

headers = files;

if nargin>1 && sort
    % Sort such that upstream headers are first.
    sorted_headers = cell(size(headers));
    for i=1:numel(headers)
      [sorted_headers{i},ind] = i_find_next(headers,headers_dir,modname);
      headers{ind} = '';
      disp(sorted_headers{i});
    end
    headers = sorted_headers;
end

writetextfile(mtfilename(fullfile(modfolder,'headerlist.txt')),headers);
end

% Returns a header from the list which doesn't include any other header in
% the list.
function [h,ind] = i_find_next(headers,headers_dir,modname,verbose)
    % This is a very blunt approach!
    for i=1:numel(headers)
        if isempty(headers{i})
            continue;
        end
        t = readtextfile(mtfilename(fullfile(headers_dir,headers{i})),true);
        top_level = true;
        for k=1:numel(headers)
            if k==i
                continue;
            end
            if isempty(headers{k})
                continue;
            end
            if i_includes(t,headers{k},modname)
                if nargin>3 && verbose
                    fprintf('%s depends on %s\n',headers{i},headers{k});
                end
                top_level = false;
                break;
            end
        end
        if top_level
            h = headers{i};
            ind = i;
            return;
        end
    end
    i_find_next(headers,headers_dir,modname,true)
    assert(false,'Couldn''t find a header without dependencies');
end


function b = i_includes(t,name,modname)
    [~,n,e] = fileparts(name);
    shortname = [n '\' e];
    b = ~isempty(regexp(t,shortname,'once'));
    if (b)
        % The shortname appears in the file.  But we need to make sure that
        % either there's no module specified or it's *this* module
        regname = strrep(name,'/','\/');
        b2 = ~isempty(regexp(t,['^#include.*' modname '\/' regname],'once'));
        if b2
            % Yes.  This model specified.
            return;
        end
        b2 = ~isempty(regexp(t,['^#include.*'  '"' regname],'once'));
        if b2
            % Yes.  No module specified.
            return;
        end
        b2 = ~isempty(regexp(t,['^#include.*' '"' shortname],'once'));
        if b2
            % Yes.  No module specified.
            return;
        end
        b = false; % could be a different relative path, but more likely to be in another module.
    end
end
