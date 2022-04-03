function out = vertcat(varargin)
%MTFILENAME/VERTCAT
%
% out = vertcat(varargin)
%
% Combines multiple mtfilename arrays into a single
% N*1 array.

out = varargin{1};
out = out(:);
for i=2:nargin
    temp = varargin{i};
    out = builtin('vertcat',out,temp(:));
end

