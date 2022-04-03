function view_last_compiler_error

e = last_compiler_error;
if isempty(e)
    disp('No error');
else
    t = [tempname '.txt'];
    mt_writetextfile(t,e);
    edit(t);
    delete(t);
end

end
