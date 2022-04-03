function c = mt_ensurecell(c)
%MT_ENSURECELL Wraps the input in a cell if it is not already a cell array
%
% c = mt_ensurecell(c);
%

if ~iscell(c)
    if isempty(c)
        % Avoid {[]}
        c = {};
    else
        c = {c};
    end
end

