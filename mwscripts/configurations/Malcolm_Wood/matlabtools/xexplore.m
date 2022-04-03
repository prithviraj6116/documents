function xexplore(name, ind)
%XEXPLORER Opens the directory containing a file
%
% xexplore(methodname)
%
% Opens the Windows Explorer for the directory containing
% the first file returned by "which -all <methodname>"
%
% xedit(methodname,N)
%
% Opens the Windows Explorer for the directory containing
% the Nth file returned by "which -all <methodname>"

a = which(name);
if ~isempty(a)
    explorer(fileparts(a));
else
    a = which('-all',name);
    if isempty(a)
        error('No matching files found');
    elseif numel(a)>1 && nargin<2
        for i=1:numel(a)
            fprintf('%d: %s\n',i,a{i});
        end
    else
        if nargin<2
            ind = 1;
        end
        explorer(fileparts(a{ind}));
    end
end


