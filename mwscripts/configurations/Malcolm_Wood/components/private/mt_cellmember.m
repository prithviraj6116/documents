function [a,b] = mt_cellmember(c,d)

persistent got_slcellmember;
if isempty(got_slcellmember)
    got_slcellmember = ~isempty(which('slcellmember'));
end

if got_slcellmember
    [a,b] = slcellmember(c,d);
else
    [a,b] = ismember(c,d);
end