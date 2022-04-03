function [type,filename,canonical] = classifyheader(filename)
    filename = i_canonicalize(filename);
    canonical = filename;
    if ~isempty(regexp(filename,'\/derived\/.*\/resources\/','once'))
        % Derived from a message catalogue file - report as a "user" header
        filename = regexprep(filename,'.*\/derived\/.*\/resources\/','$res/');
        type = 'u';
    elseif ~isempty(regexp(filename,'\/derived\/','once'))
        % Derived from somewhere else.
        type = 'd';
        filename = regexprep(filename,'.*\/derived\/','$derived/');
        filename = regexprep(filename,'glnxa64\/src\/include\/','');
    elseif ~isempty(regexp(filename,'\/3rdparty\/','once'))
        % 3rd party
        type = '3';
        filename = regexprep(filename,'.*\/glnxa64\/','$3p/');
    elseif ~isempty(regexp(filename,'\/usr\/','once'))
        % System
        type = 's';
    else
        % Source folder
        type = 'u';
        filename = regexprep(filename,'.*.*src\/include\/resources\/','$res/');
        filename = regexprep(filename,'.*.*src\/include\/','$inc/');
        filename = regexprep(filename,'.*src\/[^\/]*\/export\/include\/','$exp/');
        filename = regexprep(filename,'.*toolbox\/.*\/export\/include\/','$exp/');
        filename = regexprep(filename,'.*foundation_libraries\/','$fl');
        filename = regexprep(filename,'.*\/matlab\/simulink\/include\/','$slinc/');
        filename = strrep(filename,pwd,'$pwd');
        if strncmp(filename,'resources/',10)
            filename = ['$res/' filename(11:end)];
            type = 'r';
        elseif filename(1)~='$' && filename(1)~='/'
            filename = ['$pwd/' filename];
        end
    end
end

function filename = i_canonicalize(filename)
    % Prepend pwd to any names which don't start with "/"
    if filename(1)~='/'
        filename = fullfile(pwd,filename);
    end
    % Remove any sequences such as X/..
    s = regexprep(filename,'\/[^\.][^\/]+\/\.\.\/','/');
    if strcmp(s,filename)
        filename = s;
    else
        filename = i_canonicalize(s);
    end
end
