function ctb = readBuildList(cfg,mlroot)
% Given the name of a cluster, returns the list of "CTB" entries in
% its (old-style) config file.  Use buildlistMatcher to convert this
% to a list of components.
%
% Accepts one of:
% * The cluster name (and looks in the current sandbox)
% * The cluster name and a matlabroot
% * The path to the config file
%
% The returned cell array of strings lists all the patterns found in
% lines of the form "CTB = $CTB component
%
% ctb = readBuildList('Bslengine_integ')
% ctb = readBuildList('Bslengine_integ','/local-ssd/mwood/Bslengine_integ1')
% ctb = readBuildList('/tmp/Bslengine_integ_ctb_copy.xml')

if ischar(cfg) && ~ismember(filesep,cfg) && ~ismember('.',cfg)
    if nargin<2
        mlroot = fullfile(sbroot,'matlab');
    end
    % Location in an A cluster sandbox.
    f = fullfile(mlroot,'config','clusters',[cfg '.xml']);
    if ~exist(f,'file')
        % Location in a B cluster sandbox
        f = fullfile(fileparts(mlroot),'config','clusters',[cfg '.xml']);
    end
    if ~exist(f,'file')
        error('Cluster config file not found: %s',cfg);
    end
    f = mtfilename(f);
else
    f = mtfilename(cfg);
    if ~exist(f,'file')
        error('File not found: %s',getabs(f));
    end
end
fprintf('Reading <a href="matlab:edit(''%s'')">%s</a>\n',getabs(f),getabs(f));
d = xmlread(getabs(f));
ctb = i_readVariable(d,'COMPONENTS_TO_BUILD');
match = strncmp(ctb,'$',1);
expand = ctb(match);
ctb(match) = [];
for i=1:numel(expand)
    varname = expand{i};
    comps = i_readVariable(d,varname(2:end)); % strip the $
    ctb = [ctb ; comps]; %#ok<AGROW>
end
ctb = unique(ctb);

end

function value = i_readVariable(dom,varname)
tags = dom.getElementsByTagName('con:string');
for i=1:tags.getLength()
    t = tags.item(i-1);
    if strcmp(t.getAttribute('name'),varname)
        value = char(t.getAttribute('value'));
        value = textscan(value,'%s');
        value = value{1};
        return;
    end
end
warning('mwood:tools:readBuildList','Variable not found %s',varname);
value = {};
end

