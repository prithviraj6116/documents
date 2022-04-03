function make_compile_standalone_bruteforce(header)
% Inserts headers found before it in other source files to try and make
% this header compile standalone.

restore = mt_cd(find_module_folder(header)); %#ok<NASGU>

[~,n,e] = fileparts(header);
f = cppgrep(['\<' n e]);

minset = {};
minfile = '';
for i=1:numel(f)
    if strncmp(f{i},'m_headers',9)
        continue;
    end
    try
        h = included_headers_in_file(f{i});
    catch E
        fprintf('Error while looking in: %s\n',f{i});
        disp(E.message);
        continue;
    end
    % Find everything before our header.
    c = i_find_line(h,['\<' n e]);
    if isempty(c)
        continue;
    end
    h = h(1:c-1);
    if isempty(minset) || (numel(h) < numel(minset))
        % This is the shortest list we've found so far.
        minset = h;
        minfile = f{i};
    end
end

fprintf('Using #includes from %s\n',minfile);
disp(minset);

for i=1:numel(minset)
    if strcmp(minset{i},'version.h')
        continue;
    end
    insert_header(header,minset{i});
end

sbcc(header);

end


function n = i_find_line(t,exp)
    n = regexp(t,exp);
    n = find(~cellfun('isempty',n));
    if ~isempty(n)
        n = n(end);
    end
end