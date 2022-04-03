function out = sbfi(filename)

if nargin<1
    filename = editordoc;
end

if iscell(filename)
    for i=1:numel(filename)
        try
            if ~nargout
                sbfi(filename{i});
            else
                tmp = sbfi(filename{i});
                if i==1 || isequal(fieldnames(out),fieldnames(tmp))
                    out(i) = tmp; %#ok<AGROW>
                else
                    % This is probably because no info was found about the
                    % file.
                    fields = fieldnames(tmp);
                    for k=1:numel(fields)
                        out(i).(fields{k}) = tmp.(fields{k});
                    end
                end
            end
        catch E
            disp(E.message);
        end
    end
    return;
end

[status,out] = system(['sbfi ' filename]);
if status~=0
    error('mwood:tools:sbfi','%s',out);
end
    
if ~nargout && contains(out,'Unknown/NewFile')
    fprintf('No owner found for %s\n',filename);
    fprintf('<a href="matlab: sbfi %s">Try parent folder</a>\n',slfileparts(filename));
    fprintf('<a href="matlab: component_info %s">Try component_info</a>\n',filename);
end

if ~nargout
    disp(out);
    clear out;
else
    tokens = strsplit(out,newline);
    match = regexp(tokens,' *([^:]*): (.*)','tokens');
    out = struct;
    for i=1:numel(match)
        if ~isempty(match{i})
            m = match{i}{1};
            out.(m{1}) = m{2};
        end
    end
end

end