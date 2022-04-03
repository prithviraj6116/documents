function header = find_symbol(sym,loc)

if nargin<2
    loc = '';
end

if strncmp(sym,'const ',6)
    sym = sym(7:end);
end

map = eval('symbol_map');
if map.isKey(sym)
    header = map(sym);
    return;
end

% Not found in map.  Try to find it.

search = sym;
if any(sym==' ')
    q = strsplit(sym);
    search = q{end};
end
h = sbglobal(search);

if isempty(h)
    
    files = codesearch(search);
    [~,~,ext] = slfileparts(files);
    h = files(strcmp(ext,'.hpp'));
    
    %disp('Not found using sbglobal');
    %h = [];%sbid(search);
    if isempty(h)
        
        if contains(search,'::')
            s = regexprep(search,'^.*::','');
            header = find_symbol(s,loc);
            if ~isempty(header)
                return;
            end
        end
        
        
        %fprintf('Not found using sbid or sbglobal: %s\n',sym);
        
        restore = mt_cd(fullfile(matlabroot,'derived','glnxa64','src','include'));
        h = hppgrep(search);
        delete(restore);
        
        if isempty(h)
            fprintf('No symbol matches found for %s\n',search);
            return;
        elseif numel(h)>10
            disp('Too many matches using "grep"');
            return;
        end
    end
end

restore = mt_cd(sbroot);

already_printed = {};
for i=1:numel(h)
    if i>20
        fprintf('More than 20 matches found...\n');
        return;
    end
    [~,h{i}] = find_module_folder(h{i});
    prefix = 'export/include/';
    if strncmp(h{i},prefix,numel(prefix))
        h{i} = h{i}(numel(prefix)+1:end);
    end
    prefix = 'derived/glnxa64/src/include/';
    match = regexp(h{i},prefix,'once');
    if ~isempty(match)
        h{i} = h{i}(match+numel(prefix):end);
    end
    prefix = 'derived/win64/src/include/';
    match = regexp(h{i},prefix,'once');
    if ~isempty(match)
        h{i} = h{i}(match+numel(prefix):end);
    end
    prefix = 'derived/maci64/src/include/';
    match = regexp(h{i},prefix,'once');
    if ~isempty(match)
        h{i} = h{i}(match+numel(prefix):end);
    end
    
    if ismember(h{i},already_printed)
        continue;
    end
    
    cmd = sprintf('add_symbol(''%s'',''%s'')',sym,h{i});
    fprintf('  <a href="matlab:%s">%s</a>\n',cmd,cmd);
    if ~isempty(loc)
        cmd = sprintf('insert_header(''%s'',''%s'',''%s'')',loc,h{i},sym);
        fprintf('      <a href="matlab:%s">%s</a>\n',cmd,cmd);
    end
    
    already_printed{end+1} = h{i}; %#ok<AGROW>
end
header = {};