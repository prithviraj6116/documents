function mt_rmpath_persistent(p)
%MT_RMPATH_PERSISTNT Permanently removes (only) the specified entry from the MATLAB path
%
% mt_rmpath_persistent(p)
%
% Similar to calling: rmpath(p);savepath
% Except that if addpath or rmpath has previously been called, those
% changes will not be saved.

oldp = path; % take copy of current path
newp = pathdef; % load "persistent" path
path(newp); % and apply it temporarily.
mt_rmpath(p); % remove this entry from it
savepath; % save it in pathdef.m
path(oldp); % replace the original path
mt_rmpath(p); % remove from this one too

