function out = horzcat(varargin)
%MTFILENAME/HORZCAT
%
% out = horzcat(varargin)
%
% "Horizontal" arrays of mtfilenames are not allowed.
% This method throws an error.

if nargin>1
    error('mwood:tools:error','Horizontal concatenation of mtfilenames is not allowed');
end
out = varargin{1};
out = out(:);

