function output = sbid(sym)
% Changes to a sandbox which is known to have an up-to-date sbid cache
% and runs sbid there.
    %restore = mt_cd('/local-ssd/mwood/Bslx2');
    [~,output] = system(['sbid lid ' sym]);
    if isempty(output)
        disp('Not found');
        return;
    elseif contains(output,'Signal 127')
        disp('No sbid cache');
        return;
    end
    output = strsplit(output);
    % Remove the symbol itself.
    output = output(~strcmp(output,sym));
    % Select entries ending with .hpp
    output = output(mt_endswith(output,'.hpp'));
    if ~nargout
        if isempty(output)
            disp('Not found in any header files');
        else
            fprintf('%s\n',output{:});
        end
    else
        output = output';
    end
end