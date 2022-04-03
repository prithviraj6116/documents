function changed = fix_for_symbol(filename,symbol,interactive)
% changed = fix_for_symbol(filename,symbol,interactive)
    changed = false;
    if strncmp(symbol,'const ',6)
        symbol = symbol(7:end);
    end
    known = symbol_map;
    if known.isKey(symbol)
        insert_header(filename,known(symbol),symbol);
        changed = true;
    elseif nargin>2 && interactive
        find_symbol(symbol,filename);
    end
end
