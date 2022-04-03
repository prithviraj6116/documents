function modified = fix_using_compiler_output(message,interactive)
% modified = fix_using_compiler_output(message,interactive)

if nargin<2
    interactive = true;
end

% Fix "smart quotes"
message = strrep(message,char(8216),'''');
message = strrep(message,char(8217),'''');

% Fix UTF-8 mojibake from "smart quotes"
message = strrep(message,char([226   128   152]),'''');
message = strrep(message,char([226   128   153]),'''');

decls = symbol_map;

modified = false;

symbols_tried = {};

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' has not been declared','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' was not declared','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' in namespace ''(?<namespace>[^'']*)'' does not name a type','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' is not a member of ''(?<namespace>[^'']*)''','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' does not name a type','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: ''(?<symbol>[^'']*)'' is not a member of','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

undeclared_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: no arguments to ''(?<symbol>[^'']*)'' that depend on','names');
modified = i_apply(undeclared_symbols,decls,interactive) || modified;

incomplete_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: invalid use of incomplete type ''(?<symbol>[^'']*)''','names');
modified = i_apply(incomplete_symbols,decls,interactive) || modified;

incomplete_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: aggregate ''(?<symbol>[^'']*) [^'']*'' has incomplete type','names');
modified = i_apply(incomplete_symbols,decls,interactive) || modified;

incomplete_symbols = regexp(message,'(?<file>[^\s]*):\d*:\d*: error: incomplete type ''(?<symbol>[^'']*)'' used in','names');
modified = i_apply(incomplete_symbols,decls,interactive) || modified;


function changed = i_apply(missing,known,interactive)
    changed = false;
    for i=1:numel(missing)
        s = missing(i).symbol;
        if isfield(missing(i),'namespace')
            s = [missing(i).namespace '::' s]; %#ok<AGROW>
        end
        if strncmp(s,'const ',6)
            s = s(7:end);
        end
        if known.isKey(s)
            f = missing(i).file;
            try
                insert_header(f,known(s),s);
                changed = true;
            catch E
                disp(E.message);
            end
        elseif interactive && ~ismember(s,symbols_tried)
            find_symbol(s,missing(i).file);
            symbols_tried = [symbols_tried ; {s}]; %#ok<AGROW>
        end
    end

end

end
