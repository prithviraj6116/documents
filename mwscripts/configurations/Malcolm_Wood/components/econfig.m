function econfig(compname)

f = fullfile(sbroot,'matlab','config','components',[compname '.xml']);
edit(f);