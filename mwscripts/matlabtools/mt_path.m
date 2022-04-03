function p = mt_path(root)
%MT_PATH Returns the current MATLAB path, excluding anything inside the
% current matlabroot.
% Alternatively, if a "root" is supplied, only folders inside that root
% are returned.
%
% p = mt_path % returns all path entries outside of matlabroot
% p = mt_path(root) % returns all path entries *inside* root

fullpath = path;
p = textscan(fullpath,'%s','delimiter',pathsep);
p = p{1};
pl = lower(p);
if nargin
    match = ~strncmp(pl,lower(root),numel(root));
else
    mrt = lower(matlabroot);
    mrlen = length(mrt);
    match = strncmp(pl,mrt,mrlen);
end
p = p(~match);

