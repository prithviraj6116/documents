function geckdir(num)

if ispc
    root = '\\mathworks\AH\home\tester\bugs\';
    if ~exist(root,'dir')
        root = '\\mathworks\home\tester\bugs\';
    end        
else
    root = '/home/tester/bugs/';
end

if ischar(num)
    if num(1)=='g'
        num(1) = [];
    end
    d = sprintf('%sg%s',root,num);
else
    d = sprintf('%sg%d',root,num);
end
olddir = cd(d);
fprintf('pwd = <a href="matlab: cd %s">%s</a>\n',d,d);
fprintf('prevdir = <a href="matlab: cd %s">%s</a>\n',olddir,olddir);
