function resedit(name,p4checkout,clearonly)

if any(name==':')
    [comp,name] = strtok(name,':');
    %name = strtok(name,':');
    name = name(2:end);
else
    comp = 'Simulink';
end
filename = strrep(name,':',filesep);
f = fullfile(matlabroot,'resources',comp,'en',[filename '.xml']);

if nargin<3 || ~clearonly
    edit(f);
end

feature('clearcatalog',[comp ':' name]);
disp(f);

if nargin>1 && p4checkout
    p4edit(f);
end
