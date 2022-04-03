function f = dirtyflags(bd)

if nargin<1
    bd = bdroot;
end
p = get_param(bd,'Packager');
d = p.getDirtyManager;
f = d.getDirtyPartIDs;
end