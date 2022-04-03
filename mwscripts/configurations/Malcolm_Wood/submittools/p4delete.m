function p4delete(filename)

if nargin<1
    filename = editordoc;
end

p4edit(filename,'delete');

end
