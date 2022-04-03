function [h,inc] = locate_own_header(f)
% Find a source file's own header, if it exists in the module.
%
% [headerfile,include] = locate_own_header(sourcefile)
%

src = relativepath(mtfilename(f),pwd);
[d,n] = fileparts(src);

hname = [n '.hpp'];

h = slfullfile(pwd,d,hname);
if ~isempty(Simulink.loadsave.resolveFile(h))
    inc = hname;
    return;
end

[~,modname] = slfileparts(pwd);
h = slfullfile(d,'export','include',modname,[n '.hpp']);
if ~isempty(Simulink.loadsave.resolveFile(h))
    inc = [modname '/' hname];
    return;
end

[~,out] = system(['find export/include/' modname ' -name ' hname]);
f = strsplit(strtrim(out),char(10));
if numel(f)>1
    warning('mwood:tools:locate_own_header','Multiple candidates found for %s',hname);
    h = '';
    inc = '';
elseif isempty(f) || isempty(out)
    warning('mwood:tools:headers','%s not found',[n '.hpp']);
    h = '';
    inc = '';
else
    h = slfullfile(pwd,f{1});
    inc = relativepath(mtfilename(h),slfullfile(pwd,'export','include'));
end

