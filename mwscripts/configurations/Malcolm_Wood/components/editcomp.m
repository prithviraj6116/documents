function filename = editcomp(compname)
% Opens a component's XML file in the MATLAB Editor
    r = matlabroot;%sbroot;
    filename = fullfile(r,'config','components',[compname '.xml']);
    edit(filename);
end