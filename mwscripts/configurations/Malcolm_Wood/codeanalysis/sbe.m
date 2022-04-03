function sbe(f)

if nargin<1
    f = editordoc;
end

system(['sbe ' f]);
end