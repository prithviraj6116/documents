function cds(arg)
% Change to sandbox folder
%
% cds % nearest
% cds uk % UK
% cds ah

if nargin
    d = ['/mathworks/' upper(arg) '/devel/sandbox/mwood'];
else
    d = '/sandbox/mwood';
end
olddir = cd(d)';
fprintf('pwd = <a href="matlab: cd %s">%s</a>\n',d,d);
fprintf('prevdir = <a href="matlab: cd %s">%s</a>\n',olddir,olddir);

end