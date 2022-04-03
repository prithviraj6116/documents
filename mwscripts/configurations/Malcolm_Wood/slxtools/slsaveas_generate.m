function slsaveas_generate(start)
% Generates the export rules database for all sl_saveas clients

if nargin<1
    start = 1;
end

m = methods('sl_saveas');
% Select only methods with names beginning with 'reg'
m = m(strncmp(m,'reg',3));

startdir = pwd;
restoredir = onCleanup(@() cd(startdir));

for i=start:numel(m)
    methodfile = which(['sl_saveas/' m{i}]);
    d = slfileparts(slfileparts(methodfile));
    cd(d);
    suffix = d(numel(matlabroot)+2:end);
    fprintf('Generating export rules for <a href="matlab:edit %s/sltranslate.m">%s</a> (%d of %d)\n',...
        suffix,suffix,i,numel(m));
    %slprivate('saveasData',pwd);
    slGenerateExportDatabase(pwd);
end

p = meta.package.fromName('slexportprevious.postprocess');
f = cell(size(p.FunctionList));
for i=1:numel(p.FunctionList)
    w = which(['slexportprevious.postprocess.' p.FunctionList(i).Name]);
    f{i} = slfileparts(slfileparts(slfileparts(w)));
end
f = unique(f);
for i=1:numel(f)
    fprintf('Generating export rules for %s\n',f{i});
    slGenerateExportDatabase(f{i});
end