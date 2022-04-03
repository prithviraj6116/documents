function olddir = cd(obj)
%MTFILENAME/CD Changes to the directory specified by this mtfilename
%
% olddir = cd(obj)
%
% The mtfilename of the previous working directory is returned.

% do this first, just incase changing directory causes us to
% remove mtfilename from the path.  See mt_rmtool.
olddir = mtfilename(pwd);
cd(obj.absname);

