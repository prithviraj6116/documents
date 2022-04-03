function packager_methods(partdef_only)

m = methods('slxPackager');
if nargin>0 && partdef_only
    % Select only methods with names beginning with "partDef"
    m = m(strncmp(m,'partDef',7));
end

for i=1:numel(m)
    methodfile = which(['slxPackager/' m{i}]);
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
    d = fileparts(d); % remove @slxPackager
    d = strrep(d,matlabroot,''); % remove matlabroot
    d(1) = []; % leading separator
    fprintf('<a href="matlab:edit slxPackager/%s">%s</a> %s %s%s\n',m{i},m{i},d,cdlink,deletepfile);
end