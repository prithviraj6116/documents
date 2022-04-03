function count = linecount(filename)
% count = linecount(filename)
%
% See also line_count_report

assert(ischar(filename));
[~,~,ext] = slfileparts(filename);
if strcmp(ext,'.slx') || strcmp(ext,'.slxp') || strcmp(ext,'.mat')
    % Ignore these known binary formats.
    count = 0;
    return;
end
[status,out] = system(['cat ' filename ' | wc -l']);
if status~=0
    error('Malcolm:preproc:wc','%s',out);
end
count = str2double(out);

end

