function simmech_startup

startdir = cd(sbroot);
restoredir = onCleanup(@() cd(startdir));

!p4 unshelve -s 1118387
delete matlab/toolbox/physmod/sm/sli/m/sl_internal_customization.p
rehash toolboxcache