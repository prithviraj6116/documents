function slsaveas_deletepcode(prefix)

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
    [~,~,e] = fileparts(methodfile);
    if strcmp(e,'.p') && exist(methodfile,'file')
        delete(methodfile);
        fprintf('Deleted %s\n',methodfile);
    end
end