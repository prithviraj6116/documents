function add_symbol(sym,header)

d = fileparts(mfilename('fullpath'));
symfile = mtfilename(fullfile(d,'symbol_map.m'));
s = readtextfile(symfile);
s{end+1} = sprintf('decls(''%s'') = ''%s'';',sym,header);
backup = [tempname '_add_symbol_backup.m'];
copyfile(getabs(symfile),backup);
fprintf('Backup: %s\n',backup);
writetextfile(symfile,s);
fprintf('Write %s\n',getabs(symfile));