function c = cellcat(varargin)
%CELLCAT Joins cell arrays into a single vertical cell array
%
% c = cellcat(a,b,c...)
%
% Shorthand for c = [ a(:) ; b(:) ; c(:) ... ];

n = sum(cellfun('prodofsize',varargin));
c = cell(n,1);
count = 1;
for i=1:nargin
    n = numel(varargin{i});
    c(count:count+n-1) = varargin{i}(:);
    count = count + n;
end

