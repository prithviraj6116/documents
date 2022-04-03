function p4revert(filename)

if nargin<1
    filename = editordoc;
end

p4edit(filename,'revert');

end
