function b = strstartswith(str1,prefix)
    b = strncmp(str1,prefix,numel(prefix));
end
