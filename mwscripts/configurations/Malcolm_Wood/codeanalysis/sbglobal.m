function output = sbglobal(sym)
% Changes to a sandbox which is known to have an up-to-date sbglobal cache
% and runs sbglobal there.

    if strncmp(sym,'class ',6)
        sym = sym(7:end);
    end
    
    if any(sym==':')
        % Won't find anything with "::" in it.  Look for the bit after the
        % colons.
        n = find(sym==':');
        n = n(end);
        sym = sym(n+1:end);
    end

    %restore = mt_cd('/local-ssd/mwood/Bslx1');
    [~,output] = system(['sbglobal -s-and-r ' sym]);
    if ~nargout
        if isempty(output)
            disp('Not found');
        else
            disp(output);
        end
    else
        output = strsplit(strtrim(output));
        % Select entries ending with .hpp
        output = output(mt_endswith(output,'.hpp'));
        output = output';
    end
end