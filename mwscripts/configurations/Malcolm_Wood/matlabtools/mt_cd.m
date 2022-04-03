function restoredir = mt_cd(d)

startdir = cd(d);
restoredir = onCleanup(@() cd(startdir));

end