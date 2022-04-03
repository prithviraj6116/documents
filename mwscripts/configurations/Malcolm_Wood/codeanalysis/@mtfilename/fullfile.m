function vf = fullfile(obj,varargin)
%MTFILENAME/FULLFILE Returns an mtfilename based on the supplied parts
%
% newobj = fullfile(obj,varargin)
%
% The returned object is also an mtfilename, and its "absname" is
% composed from the original object's "absname" followed by the
% supplied parts.
%

vf = mtfilename(fullfile(obj.absname,varargin{:}));

