function [num,total,names] = count_inclusions(pattern,module)
% Count the files in a module which directly or indirectly include a particular header
%
%  num = count_inclusions(pattern)
%  [num,total,names] = count_inclusions(pattern)
%
% Uses the .d files in the "obj" folder.  The module must have been fully
% built!

if nargin<2
    module = find_module_folder(fullfile(pwd,'x.x'));
elseif iscell(module)
    num = 0;
    total = 0;
    names = {};
    for i=1:numel(module)
        [c,t] = count_inclusions(pattern,module{i});
        if ~isnan(c)
            if c ~= 0
                num = num + c;
                names{end+1} = module{i}; %#ok<AGROW>
            end
            total = total + t;
        end
        names = names(:);
    end
    fprintf('\nTotals:\n\nFound in %d files of %d\n\n',num,total);
    fprintf('Found in %d modules of %d\n',numel(names),numel(module));
    return;
end

module = mtfilename(module);
d = relativepath(module,[sbroot '/matlab']);

obj_folder = slfullfile(sbroot,'matlab/derived/glnxa64/obj',d);

% Count the inclusions.
cmd = sprintf('find %s -name "*.d" | xargs grep -l %s | wc -l',obj_folder,pattern);
[~,inclusions] = system(cmd);

if contains(inclusions,'No such file')
    fprintf('No "obj" folder found: %s\n',d);
    inclusions = '0';
    total = '0';
else
    % Count the total number of files.
    cmd = sprintf('find %s -name "*.d" | wc -l',obj_folder);
    [~,total] = system(cmd);

    fprintf('Found in %s files of %s : %s\n',strtrim(inclusions),strtrim(total),d);
end

num = str2double(inclusions);
total = str2double(total);

if nargout>2
    % Return the individual file names as well.
    cmd = sprintf('find %s -name "*.d" | xargs grep -l %s',obj_folder,pattern);
    [~,inclusions] = system(cmd);
    inclusions = strtrim(strrep(inclusions,[obj_folder '/'],''));
    names = strsplit(inclusions)';
    names = regexprep(names,'\.d$','.cpp');
    names = sort(names);
end


end
