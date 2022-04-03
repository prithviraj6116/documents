function val = gcbp(name)
%GCBP Retrieves a parameter of the current block
%
% val = gcbp(paramname)

val = get_param(gcb,name);

