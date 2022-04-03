function compile_headertests

d = dir('unittest/headertest_*.cpp');

for i=1:numel(d)
    i_compile(d(i).name);
end



end
X
function i_compile(n)
[a,b] = system(sprintf('sbcc -dc unittest/%s',n));
disp(a)
disp(b);
end