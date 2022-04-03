function debuggerQuickStart
% debuggerQuickStart - Speeds up gdb startup by deleting unused files
%
% Deletes debug information for all modules in the current sandbox except
% those named in debugger_modules.txt.
% This file should be in your sandbox root.  If not found, the one in 
% the same folder as this function will be used.
%
% Example:
%  >> debuggerQuickStart
%

try
    r = sbroot;
catch E
    disp('Not in a sandbox.  Using matlabroot');
    r = fileparts(matlabroot);
end

f = mtfilename(fullfile(r,'debugger_modules.txt'));
if ~exist(f)
    fprintf('%s not found. ',getabs(f));
    d = fileparts(mfilename('fullpath'));
    f = mtfilename(fullfile(d,'debugger_modules.txt'));
end
fprintf('Reading module list from <a href="matlab:edit %s">%s</a>\n',getabs(f),getabs(f));
t = readtextfile(f);
t = t(~strncmp('#',t,1));

modlist = sprintf('   %s\n',t{:});
question = sprintf('Delete debug information for all modules except:\n%s\n?',modlist);
answer = questdlg(question,'Debugger Quick Start','OK','Cancel','OK');
if ~strcmp(answer,'OK')
    disp('Cancelled');
    return;
end

t = [t(:) ; strcat('libmw',t(:)) ];

moddir = fullfile(r,'matlab','bin','glnxa64');

allmods = dir(fullfile(moddir,'*.dbg'));

for i=1:numel(allmods)
    % Strip both extensions
    [~,modname] = fileparts(allmods(i).name);
    [~,modname] = fileparts(modname);
    if ismember(modname,t)
        fprintf('Keep %s\n',allmods(i).name);
    else
        dbgfile = fullfile(moddir,allmods(i).name);
        delete(dbgfile);
        fprintf('%s: Delete %s\n',modname,dbgfile);
    end
end
