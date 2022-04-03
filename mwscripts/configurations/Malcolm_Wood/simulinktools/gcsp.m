function val = gcsp(name)
%GCBP Retrieves a parameter of the current block diagram
%
% val = gcsp(paramname)

val = get_param(bdroot,name);

