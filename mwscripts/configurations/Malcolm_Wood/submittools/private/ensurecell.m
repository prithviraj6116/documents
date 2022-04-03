function c = ensurecell(c)
%ENSURECELL Wraps the input in a cell if it is not already a cell array
%
% c = ensurecell(c);
%

if ~iscell(c)
    if isempty(c)
        % Avoid {[]}
        c = {};
    else
        c = {c};
    end
end

