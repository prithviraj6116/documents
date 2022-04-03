function h = hasname(obj)
%MTFILENAME/HASNAME True for an object with either an "absname" or a "command"
%
% h = hasname(obj)
%
% h is a logical array with the same number of elements as obj.

h = logical(size(obj));
for i=1:length(obj)
    h(i) = ~isempty(obj(i).absname) | ~isempty(obj(i).command);
end

