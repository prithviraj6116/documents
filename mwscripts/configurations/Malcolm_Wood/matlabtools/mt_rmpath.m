function mt_rmpath(varargin)
%MT_RMPATH Modification of rmpath to allowbasic wildcards 
%
% mt_rmpath(path)
% mt_rmpath(path1, path2, ...)
%
% Each path is a string or a cell array of strings.
% If the final character in the path is a star (*),
% all entries in the MATLAB path which begin with the
% specified prefix are removed.
%

for i=1:nargin
    p = varargin{i};
    if iscell(p)
        for k=1:length(p)
            i_rmpath(p{k});
        end
    else
        i_rmpath(p);
    end
end

%%%%%%%%%%%%%%%%%%%
function i_rmpath(p)

p = char(p);

if p(end)=='*'
    p = p(1:end-1);
    numc = length(p);
    fullpath = path;
	while 1
        [c,fullpath] = strtok(fullpath,pathsep);
        if isempty(c)
            break;
        elseif length(c)>=numc && strcmpi(p,c(1:numc))
            fprintf('Removing "%s" from the MATLAB path\n',c);
            rmpath(c);
        end
	end
elseif mt_onpath(p)
    rmpath(p);
end
