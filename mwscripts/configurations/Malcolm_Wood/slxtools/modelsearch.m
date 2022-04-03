function modelsearch(str,files)
% A not-yet-very-good wrapper for the Model Search functionality.

if nargin<2 || isempty(files)
    files = {'*.slx','*.mdl'};
end

if ischar(files)
    if any(files=='*')
        f = dir(files);
        for i=1:numel(f)
            i_search(str,slfullfile(f(i).folder,f(i).name));
        end
    else
        i_search(str,files);
    end
else
    for i=1:numel(files)
        modelsearch(str,files{i});
    end
end

end

function i_search(str,filename)

if iscell(str)
    m = cell(size(str));
    [m{:}] = Simulink.loadsave.findAll(filename,str{:});
    for i=1:numel(m)
        m{i} = m{i}{1};
    end
    if all(cellfun(@isempty,m))
        fprintf('No matches in %s\n',filename);
    end
else
    m = Simulink.loadsave.findAll(filename,str);
    i_show(m{1},str,filename);
end
end

function i_show(m,q,filename)

if isempty(m)
    fprintf('No matches in %s\n',filename);
else
    fprintf('Matches in %s:\n',filename);
    for i=1:numel(m)
        disp(m(i));
    end
end
end