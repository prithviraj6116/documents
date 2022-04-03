function z = qetruncatepathfromdir( pathtofile, dirtocutfrom )

% if toolbox is in the name, chop off everything before toolbox

%   $Revision: 1.1 $  $Date: 2004/10/15 10:55:42 $
namelist = {};

% if filesep are present make sure to separate by filesep
% otherwise try to separate by unix style file separator
if(findstr(pathtofile, filesep))
    namelist = stringtokens(pathtofile, filesep);
elseif( ispc )
    namelist = stringtokens(pathtofile, '/');
else
    namelist = stringtokens(pathtofile, '\');
end

% try to find toolbox directory
toolboxindices = strmatch(dirtocutfrom, namelist);

% test to see if it is empty, if it is, no toolbox directory
% was found, so just leave the directory alone.
if(isempty(toolboxindices))
    toolboxindices = 1;
end

% now take what is in the array and make a path to it
z = '';

for counti = max(toolboxindices) : length(namelist)
    z = fullfile(z, char(namelist(counti)));
end

return;



function z = stringtokens(tokenizethis, withthis)
z = {};

while(1)
    [T, tokenizethis] = strtok(tokenizethis, withthis);
    if(~isempty(T))
        z = cat(1, z, {T});
    else
        break;
    end
end

return;
