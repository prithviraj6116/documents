function b = mt_endswith(str,pattern)

if iscell(str)
    b = false(size(str));
    for i=1:numel(str)
        b(i) = mt_endswith(str{i},pattern);
    end
    return;
end

b = false;
n = numel(pattern);
if numel(str)<n
    return;
end
b = strcmp(str(end-n+1:end),pattern);
end