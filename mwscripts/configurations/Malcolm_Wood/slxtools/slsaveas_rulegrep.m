function slsaveas_rulegrep(pattern)
% Runs "grep" on all sltranslate.m and slsaveas_sa* files

m = methods('sl_saveas');
% Select only methods with names beginning with 'reg'
m = m(strncmp(m,'reg',3));

startdir = pwd;
restoredir = onCleanup(@() cd(startdir));

for i=1:numel(m)
    methodfile = which(['sl_saveas/' m{i}]);
    d = fileparts(fileparts(methodfile));
    cd(d);
    disp(['<a href="matlab:edit ' d filesep 'sltranslate.m">' d filesep 'sltranslate.m</a>']);
    system(['grep -nH ' pattern ' sltranslate.m']);
end

cd(startdir);

% Select only methods with names beginning with 'reg'
m = methods('sl_saveas');
m = m(strncmp(m,'sa',2));

for i=1:numel(m)
    methodfile = which(['sl_saveas/' m{i}]);
    d = fileparts(methodfile);
    cd(d);
    disp(['<a href="matlab:edit ' methodfile '">sl_saveas/' m{i} '.m</a>']);
    system(['grep -nH ' pattern ' ' m{i} '.m']);
end