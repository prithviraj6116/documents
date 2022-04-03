function p4add(filename)

if nargin<1
    filename = editordoc;
end

p4edit(filename,'add');

end
