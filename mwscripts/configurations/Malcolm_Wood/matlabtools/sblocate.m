function files = sblocate(pattern)

[status,out] = system(['sblocate ' pattern]);
if status~=0
    files = {}; % Not found
else
    files = strsplit(strtrim(out),newline)';
end    

end