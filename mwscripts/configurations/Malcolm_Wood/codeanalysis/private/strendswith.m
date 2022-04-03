function b = strendswith(str1,suffix)
    n = numel(suffix);
    b = strcmp(str1(end-n+1:end),suffix);
end
