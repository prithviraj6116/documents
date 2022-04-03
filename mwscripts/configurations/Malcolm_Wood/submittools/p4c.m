function [out,desc] = p4c(all_clients)
% p4c - shows details of Perforce changesets
%
% p4c   - prints details of Perforce changesets in the current client
% p4c(true) - prints details of all the user's Perforce changesets
% [changes,desc] = p4c  - returns numbers and descriptions of changesets
%

    client = mt_readtextfile(slfullfile(sbroot,'.perforce'));
    client = strrep(client{1},'P4CLIENT=','');
    if nargin && all_clients
        clientflag = '';
    else
        clientflag = [ '-c ' client ];
    end
    
    user = getenv('USER');
    [~,output] = system(sprintf('p4 changes -u %s %s -s pending',user,clientflag));
    %disp(strtrim(output));
    %if nargout
    m = regexp(output,'Change (?<num>\d*) on [^\s]* by \w*@(?<client>[^\s]*)','names');
    if ~isempty(m)
        out = {m.num}';
    else
        disp('No changesets found');
        out = {};
        return;
    end
        
    %if nargout>1
    desc = cell(size(out));
    for i=1:numel(out)
        changeset = out{i};
        [~,output] = system(['p4 describe ' changeset]);
        t = strsplit(output,newline);
        desc{i} = strtrim(t{2});
        
        if strcmp(m(i).client,client)
            % Changeset in this client
            fprintf('<a href="matlab:changeset_to_diffreport %s">c%s</a>: %s\n',...
                changeset,changeset,desc{i});
        else
            fprintf('c%s (client %s): %s\n',...
                changeset,m(i).client,desc{i});
        end
    end
    %end
        
    %end
    
    if ~nargout
        clear out;
    end
end