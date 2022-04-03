function slsaveas_methods(prefix)

m = methods('sl_saveas');
if nargin>0
    % Select only methods with names beginning with the supplied prefix
    m = m(strncmp(m,prefix,numel(prefix)));
end

for i=1:numel(m)
    methodfile = which(['sl_saveas/' m{i}]);
    if isempty(methodfile)
        continue; % ignore built-in methods
    end
    [d,~,e] = fileparts(methodfile);
    if strcmp(e,'.p') && exist(methodfile,'file')
        deletepfile = sprintf(' (<a href="matlab:delete %s">delete P-file</a>)',methodfile);
    else
        deletepfile = '';
    end
    cdlink = sprintf('(<a href="matlab:cd %s">cd</a>)',d);
    d = fileparts(d); % remove @sl_saveas
    d = strrep(d,matlabroot,''); % remove matlabroot
    d(1) = []; % leading separator
    fprintf('<a href="matlab:edit sl_saveas/%s">%s</a> %s %s%s\n',m{i},m{i},d,cdlink,deletepfile);
end